from django.core.exceptions import ValidationError
from django.db import transaction

from core.models import PlatformLegalIdentity


def get_active_platform_legal_identity():
    return (
        PlatformLegalIdentity.objects
        .filter(is_active=True)
        .order_by("-effective_from", "-created_at")
        .first()
    )


def require_active_platform_legal_identity():
    identity = get_active_platform_legal_identity()

    if identity is None:
        raise ValidationError(
            "Aucune identité juridique EKEFLICKS active."
        )

    return identity


@transaction.atomic
def activate_platform_legal_identity(identity):
    locked = PlatformLegalIdentity.objects.select_for_update()

    identity = locked.get(pk=identity.pk)

    required = {
        "legal_name": identity.legal_name,
        "registered_office": identity.registered_office,
        "city": identity.city,
        "country": identity.country,
    }

    missing = [
        key
        for key, value in required.items()
        if not str(value or "").strip()
    ]

    if missing:
        raise ValidationError(
            "Identité juridique incomplète : "
            + ", ".join(missing)
        )

    locked.filter(is_active=True).exclude(
        pk=identity.pk
    ).update(is_active=False)

    identity.is_active = True
    identity.save(
        update_fields=[
            "is_active",
            "updated_at",
        ]
    )

    return identity
