import re
from io import BytesIO

from PIL import Image, UnidentifiedImageError
from rest_framework import serializers

from core.models import TechnicalSpecification


_IMAGE_SECTION_BY_MEDIA_TYPE = {
    "poster": "poster",
    "backdrop": "banner",
}


def _published_specification():
    return (
        TechnicalSpecification.objects
        .filter(is_published=True)
        .order_by("-published_at", "-created_at")
        .first()
    )


def _spec_rule_map(specification):
    rules = {}

    if specification is None:
        return rules

    sections = (
        specification.sections
        if isinstance(specification.sections, list)
        else []
    )

    for section in sections:
        if not isinstance(section, dict):
            continue

        items = section.get("items") or []

        if not isinstance(items, list):
            continue

        for item in items:
            if not isinstance(item, dict):
                continue

            if not item.get("auto_validation"):
                continue

            key = str(item.get("rule_key") or "").strip()

            if not key:
                continue

            rules[key] = str(
                item.get("value") or ""
            ).strip()

    return rules


def _parse_ratio(value):
    match = re.search(
        r"(\d+(?:[.,]\d+)?)\s*:\s*(\d+(?:[.,]\d+)?)",
        value or "",
    )

    if not match:
        raise ValueError("ratio illisible")

    left = float(match.group(1).replace(",", "."))
    right = float(match.group(2).replace(",", "."))

    if left <= 0 or right <= 0:
        raise ValueError("ratio invalide")

    return left, right


def _parse_resolution(value):
    match = re.search(
        r"(\d+)\s*[x×]\s*(\d+)",
        value or "",
        flags=re.IGNORECASE,
    )

    if not match:
        raise ValueError("résolution illisible")

    return int(match.group(1)), int(match.group(2))


def _parse_max_size_bytes(value):
    match = re.search(
        r"(\d+(?:[.,]\d+)?)\s*(?:mo|mb)",
        value or "",
        flags=re.IGNORECASE,
    )

    if not match:
        raise ValueError("poids maximal illisible")

    size_mb = float(
        match.group(1).replace(",", ".")
    )

    return int(size_mb * 1024 * 1024)


def _parse_formats(value):
    normalized = (value or "").lower()

    formats = set()

    if "png" in normalized:
        formats.add("PNG")

    if (
        "jpg" in normalized
        or "jpeg" in normalized
    ):
        formats.add("JPEG")

    return formats


def _read_uploaded_bytes(uploaded_file):
    try:
        uploaded_file.seek(0)
    except Exception:
        pass

    data = uploaded_file.read()

    try:
        uploaded_file.seek(0)
    except Exception:
        pass

    return data


def _validate_rgb(image):
    # Les images avec alpha ou palette peuvent être techniquement
    # valides comme PNG mais le cahier EKEFLICKS exige RGB.
    if image.mode != "RGB":
        raise serializers.ValidationError({
            "file": (
                "L'image doit être en espace colorimétrique RGB. "
                f"Mode détecté : {image.mode}."
            )
        })


def validate_image_against_published_spec(
    uploaded_file,
    media_type,
):
    """
    Valide poster / bannière à partir de la
    TechnicalSpecification actuellement publiée.

    Si aucune spec n'est publiée, cette fonction ne bloque pas
    les anciens environnements/tests.
    """
    spec_key = _IMAGE_SECTION_BY_MEDIA_TYPE.get(
        media_type
    )

    if spec_key is None:
        return {
            "validated": False,
            "reason": "media_type_not_image",
        }

    specification = _published_specification()

    if specification is None:
        return {
            "validated": False,
            "reason": "no_published_specification",
        }

    rules = _spec_rule_map(specification)

    required_keys = [
        f"{spec_key}.aspect_ratio",
        f"{spec_key}.min_resolution",
        f"{spec_key}.max_size_mb",
        f"{spec_key}.formats",
    ]

    missing_rules = [
        key
        for key in required_keys
        if not rules.get(key)
    ]

    if missing_rules:
        raise serializers.ValidationError({
            "technical_specification": (
                "Le cahier des charges publié est incomplet "
                "pour la validation automatique : "
                + ", ".join(missing_rules)
            )
        })

    payload = _read_uploaded_bytes(uploaded_file)

    if not payload:
        raise serializers.ValidationError({
            "file": "Le fichier image est vide."
        })

    max_size = _parse_max_size_bytes(
        rules[f"{spec_key}.max_size_mb"]
    )

    if len(payload) > max_size:
        raise serializers.ValidationError({
            "file": (
                "Fichier trop volumineux : "
                f"{len(payload) / (1024 * 1024):.2f} Mo. "
                "Maximum autorisé : "
                f"{max_size / (1024 * 1024):.0f} Mo."
            )
        })

    try:
        with Image.open(BytesIO(payload)) as image:
            image.load()

            detected_format = (
                str(image.format or "").upper()
            )

            width, height = image.size

            allowed_formats = _parse_formats(
                rules[f"{spec_key}.formats"]
            )

            if (
                allowed_formats
                and detected_format not in allowed_formats
            ):
                raise serializers.ValidationError({
                    "file": (
                        "Format image non conforme. "
                        f"Format détecté : {detected_format or 'inconnu'}. "
                        "Formats autorisés : "
                        + ", ".join(sorted(allowed_formats))
                        + "."
                    )
                })

            min_width, min_height = _parse_resolution(
                rules[f"{spec_key}.min_resolution"]
            )

            if (
                width < min_width
                or height < min_height
            ):
                raise serializers.ValidationError({
                    "file": (
                        "Résolution insuffisante : "
                        f"{width} × {height}. "
                        "Minimum requis : "
                        f"{min_width} × {min_height}."
                    )
                })

            ratio_width, ratio_height = _parse_ratio(
                rules[f"{spec_key}.aspect_ratio"]
            )

            # Vérification exacte sans erreur flottante.
            left = width * ratio_height
            right = height * ratio_width

            if abs(left - right) > 0.000001:
                raise serializers.ValidationError({
                    "file": (
                        "Ratio non conforme : "
                        f"{width}:{height}. "
                        "Ratio requis : "
                        f"{ratio_width:g}:{ratio_height:g}."
                    )
                })

            _validate_rgb(image)

            return {
                "validated": True,
                "specification_id": str(
                    specification.id
                ),
                "specification_version": (
                    specification.version
                ),
                "media_type": media_type,
                "spec_key": spec_key,
                "format": detected_format,
                "width": width,
                "height": height,
                "size_bytes": len(payload),
                "mode": image.mode,
            }

    except serializers.ValidationError:
        raise
    except UnidentifiedImageError as exc:
        raise serializers.ValidationError({
            "file": (
                "Le fichier envoyé n'est pas une image "
                "PNG/JPG valide."
            )
        }) from exc
    except (OSError, ValueError) as exc:
        raise serializers.ValidationError({
            "file": (
                "Impossible de valider techniquement "
                f"l'image : {exc}"
            )
        }) from exc
