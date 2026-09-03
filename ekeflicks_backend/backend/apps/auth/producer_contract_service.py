from __future__ import annotations

import hashlib
import io
from dataclasses import dataclass
from pathlib import Path

from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import storages
from django.utils import timezone

from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfbase.ttfonts import TTFont

from core.models.producers import ProducerAccount, ProducerAgreement


CONTRACT_TEMPLATE_PREFIX = "contrat-producteur-ekeflicks-"


CONTRACT_FONT_REGULAR = "EKEFLICKS-NotoSerif"
CONTRACT_FONT_BOLD = "EKEFLICKS-NotoSerif-Bold"

CONTRACT_FONT_REGULAR_PATH = (
    "/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf"
)
CONTRACT_FONT_BOLD_PATH = (
    "/usr/share/fonts/truetype/noto/NotoSerif-Bold.ttf"
)


def _register_contract_fonts():
    if CONTRACT_FONT_REGULAR not in pdfmetrics.getRegisteredFontNames():
        if not Path(CONTRACT_FONT_REGULAR_PATH).exists():
            raise ProducerContractError(
                "La police Noto Serif Regular est introuvable."
            )
        pdfmetrics.registerFont(
            TTFont(
                CONTRACT_FONT_REGULAR,
                CONTRACT_FONT_REGULAR_PATH,
            )
        )

    if CONTRACT_FONT_BOLD not in pdfmetrics.getRegisteredFontNames():
        if not Path(CONTRACT_FONT_BOLD_PATH).exists():
            raise ProducerContractError(
                "La police Noto Serif Bold est introuvable."
            )
        pdfmetrics.registerFont(
            TTFont(
                CONTRACT_FONT_BOLD,
                CONTRACT_FONT_BOLD_PATH,
            )
        )


class ProducerContractError(Exception):
    pass


@dataclass(frozen=True)
class GeneratedProducerContract:
    pdf_bytes: bytes
    sha256: str
    effective_date: object


def _clean(value) -> str:
    return "" if value is None else str(value).strip()


def _template_path() -> Path:
    version = _clean(
        settings.PRODUCER_AGREEMENT_CURRENT_VERSION
    )

    if (
        not version
        or any(
            char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
            for char in version
        )
    ):
        raise ProducerContractError(
            "Version du contrat Producteur invalide."
        )

    filename = f"{CONTRACT_TEMPLATE_PREFIX}{version}.pdf"

    path = (
        Path(settings.BASE_DIR)
        / "apps"
        / "auth"
        / "contract_templates"
        / filename
    )

    if not path.exists():
        raise ProducerContractError(
            "Le contrat canonique Producteur est introuvable "
            f"pour la version {version}."
        )

    return path


def _producer_data(account: ProducerAccount) -> dict:
    data = {
        "company_name": _clean(account.company_name),
        "legal_name": _clean(account.legal_name),
        "legal_form": _clean(account.legal_form),
        "country_code": _clean(account.country_code).upper(),
        "address": _clean(account.address),
        "city": _clean(account.city),
        "registration_number": _clean(account.registration_number),
        "tax_number": _clean(account.tax_number),
        "representative_name": _clean(account.representative_name),
        "representative_role": _clean(account.representative_role),
        "email": _clean(account.user.email),
        "phone": _clean(account.phone or account.user.phone),
    }

    required = {
        "Nom commercial / structure": data["company_name"],
        "Raison sociale": data["legal_name"],
        "Forme juridique": data["legal_form"],
        "Pays": data["country_code"],
        "Adresse": data["address"],
        "Ville": data["city"],
        "Numero d'immatriculation": data["registration_number"],
        "Representant legal": data["representative_name"],
        "Fonction du representant": data["representative_role"],
        "Email": data["email"],
    }

    missing = [name for name, value in required.items() if not value]

    if missing:
        raise ProducerContractError(
            "Informations professionnelles incompletes : "
            + ", ".join(missing)
            + "."
        )

    return data


def _cover(c, x, y, width, height=16):
    c.setFillColorRGB(1, 1, 1)
    c.rect(x, y, width, height, stroke=0, fill=1)


def _text(c, x, y, value, size=9):
    c.setFillColorRGB(0, 0, 0)
    c.setFont(CONTRACT_FONT_REGULAR, size)
    c.drawString(x, y, _clean(value))


def _draw_fitted_text(
    c,
    x,
    y,
    value,
    *,
    max_width,
    preferred_size=9,
    min_size=6.5,
    font=CONTRACT_FONT_REGULAR,
):
    """
    Draw the complete legal value without truncation.

    Font size is reduced until the complete text fits.
    If the full value cannot fit even at min_size, contract
    generation stops instead of altering legal information.
    """
    value = _clean(value)

    size = float(preferred_size)

    while size >= float(min_size):
        if stringWidth(value, font, size) <= max_width:
            c.setFillColorRGB(0, 0, 0)
            c.setFont(font, size)
            c.drawString(x, y, value)
            return

        size -= 0.25

    raise ProducerContractError(
        "Une information juridique est trop longue pour le contrat : "
        + value
    )


def _address(data):
    value = data["address"]
    if data["city"]:
        value = f'{value}, {data["city"]}'
    return value


def _overlay_page_1(data, effective_date):
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(612, 792))

    _cover(c, 300, 602, 230)
    _text(c, 300, 605.5, effective_date.strftime("%d/%m/%Y"), 10)

    _cover(c, 55, 297, 505, 17)
    _cover(c, 55, 280, 505, 17)
    _cover(c, 55, 264, 505, 17)

    line1 = (
        f'{data["legal_name"]}, forme juridique {data["legal_form"]}, '
        f'etabli(e) en {data["country_code"]},'
    )

    tax = (
        f', numero fiscal {data["tax_number"]}'
        if data["tax_number"]
        else ""
    )

    line2 = (
        f'adresse {_address(data)}, numero d\'immatriculation '
        f'{data["registration_number"]}{tax},'
    )

    line3 = (
        f'represente(e) par {data["representative_name"]}, '
        f'en qualite de {data["representative_role"]}, '
        'ci-apres denomme(e) le « Producteur » ;'
    )

    _draw_fitted_text(
        c, 59.65, 301.35, line1,
        max_width=500,
        preferred_size=9,
        min_size=6.5,
    )
    _draw_fitted_text(
        c, 59.65, 284.95, line2,
        max_width=500,
        preferred_size=8.7,
        min_size=6.5,
    )
    _draw_fitted_text(
        c, 59.65, 268.55, line3,
        max_width=500,
        preferred_size=8.5,
        min_size=6.5,
    )

    c.save()
    return buf.getvalue()


def _overlay_page_12(data):
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(612, 792))

    values = [
        (380.25, "Raison sociale", data["legal_name"]),
        (354.85, "Nom commercial", data["company_name"]),
        (329.45, "Pays", data["country_code"]),
        (304.05, "Forme juridique", data["legal_form"]),
        (
            278.65,
            "Numero d'immatriculation",
            data["registration_number"],
        ),
        (
            253.25,
            "Numero fiscal",
            data["tax_number"] or "Non renseigne",
        ),
        (227.85, "Adresse", data["address"]),
        (202.45, "Ville", data["city"]),
        (
            177.05,
            "Representant",
            data["representative_name"],
        ),
        (
            151.65,
            "Qualite du representant",
            data["representative_role"],
        ),
        (
            126.25,
            "Email du compte Producteur",
            data["email"],
        ),
        (
            100.85,
            "Telephone",
            data["phone"] or "Non renseigne",
        ),
        (
            75.45,
            "Devise de paiement",
            "A definir dans l'espace de paiement",
        ),
        (
            50.05,
            "Moyen de paiement",
            "A definir dans l'espace de paiement",
        ),
    ]

    for y, label, value in values:
        _cover(c, 55, y - 3, 505, 17)
        _draw_fitted_text(
            c,
            59.65,
            y,
            f"{label} : {value}",
            max_width=500,
            preferred_size=9,
            min_size=6.5,
        )

    c.save()
    return buf.getvalue()

def _overlay_page_13(
    data,
    *,
    ekeflicks_signed_at,
    producer_signed_at=None,
    presented_hash="",
):
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(612, 792))

    # ======================================================
    # TABLEAU DE SIGNATURE
    # ======================================================

    left = 55
    middle = 302
    right = 562

    top = 720
    bottom = 558

    # Fond blanc propre.
    _cover(
        c,
        left,
        bottom,
        right - left,
        top - bottom,
    )

    c.setStrokeColorRGB(0, 0, 0)
    c.setLineWidth(0.45)

    # Contour.
    c.rect(
        left,
        bottom,
        right - left,
        top - bottom,
        stroke=1,
        fill=0,
    )

    # Séparation colonnes.
    c.line(
        middle,
        bottom,
        middle,
        top,
    )

    # Lignes.
    rows = [
        705,
        690,
        675,
        660,
        645,
        630,
        615,
        585,
        558,
    ]

    for y in rows:
        c.line(left, y, right, y)

    labels = [
        (708.5, "Version du contrat"),
        (693.5, "Titre"),
        (678.5, "Producteur"),
        (663.5, "Nom du signataire"),
        (648.5, "Qualite"),
        (633.5, "Pays"),
        (618.5, "Date et heure UTC"),
        (588.5, "Methode"),
        (573.0, "Empreinte SHA-256"),
        (560.5, "Acceptation"),
    ]

    for y, label in labels:
        _draw_fitted_text(
            c,
            59.65,
            y,
            label,
            max_width=235,
            preferred_size=8.5,
            min_size=6.5,
        )

    # ------------------------------------------------------
    # Valeurs
    # ------------------------------------------------------

    _draw_fitted_text(
        c,
        306.1,
        708.5,
        settings.PRODUCER_AGREEMENT_CURRENT_VERSION,
        max_width=250,
        preferred_size=8.5,
        min_size=6.5,
    )

    _draw_fitted_text(
        c,
        306.1,
        693.5,
        settings.PRODUCER_AGREEMENT_TITLE,
        max_width=250,
        preferred_size=8.5,
        min_size=6.5,
    )

    _draw_fitted_text(
        c,
        306.1,
        678.5,
        data["legal_name"],
        max_width=250,
        preferred_size=8.5,
        min_size=6.5,
    )

    _draw_fitted_text(
        c,
        306.1,
        663.5,
        data["representative_name"],
        max_width=250,
        preferred_size=8.5,
        min_size=6.5,
    )

    _draw_fitted_text(
        c,
        306.1,
        648.5,
        data["representative_role"],
        max_width=250,
        preferred_size=8.5,
        min_size=6.5,
    )

    _text(
        c,
        306.1,
        633.5,
        data["country_code"],
        8.5,
    )

    if producer_signed_at:
        signature_date = producer_signed_at.strftime(
            "%Y-%m-%d %H:%M:%S UTC"
        )
        fingerprint = presented_hash
    else:
        signature_date = "En attente de signature du Producteur"
        fingerprint = "Empreinte generee avant acceptation"

    _draw_fitted_text(
        c,
        306.1,
        618.5,
        signature_date,
        max_width=250,
        preferred_size=8.0,
        min_size=6.0,
    )

    _draw_fitted_text(
        c,
        306.1,
        600,
        "Signature electronique EKEFLICKS / clickwrap",
        max_width=250,
        preferred_size=7.7,
        min_size=6.0,
    )

    _draw_fitted_text(
        c,
        306.1,
        589,
        "ou prestataire externe",
        max_width=250,
        preferred_size=7.7,
        min_size=6.0,
    )

    _draw_fitted_text(
        c,
        306.1,
        573,
        fingerprint,
        max_width=250,
        preferred_size=6.3,
        min_size=5.0,
    )

    _draw_fitted_text(
        c,
        306.1,
        560.5,
        "Je reconnais avoir lu et accepte le contrat.",
        max_width=250,
        preferred_size=6.8,
        min_size=5.5,
    )

    # ======================================================
    # SIGNATURE INSTITUTIONNELLE EKEFLICKS
    # ======================================================

    _cover(c, 55, 449, 245, 75)

    c.setFillColorRGB(0, 0, 0)
    c.setFont(CONTRACT_FONT_BOLD, 9)

    c.drawString(
        59.65,
        505,
        "EKEFLICKS",
    )

    _draw_fitted_text(
        c,
        59.65,
        490,
        settings.EKEFLICKS_CONTRACT_SIGNER_NAME,
        max_width=235,
        preferred_size=8.5,
        min_size=6.5,
    )

    _draw_fitted_text(
        c,
        59.65,
        477,
        settings.EKEFLICKS_CONTRACT_SIGNER_ROLE,
        max_width=235,
        preferred_size=8.5,
        min_size=6.5,
    )

    _text(
        c,
        59.65,
        464,
        ekeflicks_signed_at.strftime(
            "%Y-%m-%d %H:%M:%S UTC"
        ),
        8.2,
    )

    c.save()
    return buf.getvalue()

def _merge(page, overlay):
    page.merge_page(PdfReader(io.BytesIO(overlay)).pages[0])


def _write(reader):
    out = io.BytesIO()
    writer = PdfWriter()

    for page in reader.pages:
        writer.add_page(page)

    writer.write(out)
    return out.getvalue()


def generate_presented_contract(
    account: ProducerAccount,
    *,
    ekeflicks_signed_at=None,
) -> GeneratedProducerContract:
    _register_contract_fonts()
    data = _producer_data(account)
    ekeflicks_signed_at = ekeflicks_signed_at or timezone.now()
    effective_date = timezone.localdate(ekeflicks_signed_at)

    reader = PdfReader(str(_template_path()))

    if len(reader.pages) != 13:
        raise ProducerContractError(
            "La version canonique doit contenir 13 pages."
        )

    _merge(
        reader.pages[0],
        _overlay_page_1(data, effective_date),
    )

    _merge(
        reader.pages[11],
        _overlay_page_12(data),
    )

    _merge(
        reader.pages[12],
        _overlay_page_13(
            data,
            ekeflicks_signed_at=ekeflicks_signed_at,
        ),
    )

    pdf_bytes = _write(reader)

    return GeneratedProducerContract(
        pdf_bytes=pdf_bytes,
        sha256=hashlib.sha256(pdf_bytes).hexdigest(),
        effective_date=effective_date,
    )


def generate_signed_contract(
    account: ProducerAccount,
    *,
    presented_contract: GeneratedProducerContract,
    signed_at,
    ekeflicks_signed_at,
) -> GeneratedProducerContract:
    _register_contract_fonts()
    data = _producer_data(account)

    reader = PdfReader(io.BytesIO(presented_contract.pdf_bytes))

    _merge(
        reader.pages[12],
        _overlay_page_13(
            data,
            ekeflicks_signed_at=ekeflicks_signed_at,
            producer_signed_at=signed_at,
            presented_hash=presented_contract.sha256,
        ),
    )

    pdf_bytes = _write(reader)

    return GeneratedProducerContract(
        pdf_bytes=pdf_bytes,
        sha256=hashlib.sha256(pdf_bytes).hexdigest(),
        effective_date=presented_contract.effective_date,
    )


def store_presented_contract(
    agreement: ProducerAgreement,
    contract: GeneratedProducerContract,
) -> str:
    storage = storages["producer_contracts"]

    key = (
        f"producer-agreements/{agreement.producer_account_id}/"
        f"{agreement.contract_version}/"
        f"agreement-{agreement.id}-presented.pdf"
    )

    return storage.save(key, ContentFile(contract.pdf_bytes))


def store_signed_contract(
    agreement: ProducerAgreement,
    contract: GeneratedProducerContract,
) -> str:
    storage = storages["producer_contracts"]

    key = (
        f"producer-agreements/{agreement.producer_account_id}/"
        f"{agreement.contract_version}/"
        f"agreement-{agreement.id}-signed.pdf"
    )

    return storage.save(key, ContentFile(contract.pdf_bytes))
