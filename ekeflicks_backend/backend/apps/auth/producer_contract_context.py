from apps.auth.platform_legal_identity import (
    require_active_platform_legal_identity,
)


def _value(value):
    if value is None:
        return ""
    return str(value).strip()


def producer_contract_context(account):
    """
    Dynamic values used to render a new producer contract.

    These values are presentation inputs only.
    Signed agreements retain immutable snapshots.
    """
    user = getattr(account, "user", None)

    return {
        "producer_legal_name": _value(
            getattr(account, "legal_name", "")
            or getattr(account, "company_name", "")
        ),
        "producer_company_name": _value(
            getattr(account, "company_name", "")
        ),
        "producer_legal_form": _value(
            getattr(account, "legal_form", "")
        ),
        "producer_country_code": _value(
            getattr(account, "country_code", "")
        ).upper(),
        "producer_address": _value(
            getattr(account, "address", "")
        ),
        "producer_city": _value(
            getattr(account, "city", "")
        ),
        "producer_registration_number": _value(
            getattr(account, "registration_number", "")
        ),
        "producer_tax_number": _value(
            getattr(account, "tax_number", "")
        ),
        "producer_representative_name": _value(
            getattr(account, "representative_name", "")
        ),
        "producer_representative_role": _value(
            getattr(account, "representative_role", "")
        ),
        "producer_email": _value(
            getattr(user, "email", "")
            or getattr(account, "email", "")
        ),
        "producer_phone": _value(
            getattr(account, "phone", "")
        ),
    }


def platform_contract_context():
    identity = require_active_platform_legal_identity()

    office = _value(identity.registered_office)
    postal = _value(identity.postal_code)
    city = _value(identity.city)

    return {
        "ekeflicks_legal_name": _value(identity.legal_name),
        "ekeflicks_legal_form": _value(identity.legal_form),
        "ekeflicks_capital": _value(identity.capital),
        "ekeflicks_registered_office": office,
        "ekeflicks_postal_code": postal,
        "ekeflicks_city": city,
        "ekeflicks_country": _value(identity.country),
        "ekeflicks_siret": _value(identity.siret),
        "ekeflicks_rcs": _value(identity.rcs),
        "ekeflicks_vat_number": _value(identity.vat_number),
        "ekeflicks_representative_name": _value(
            identity.representative_name
        ),
        "ekeflicks_representative_role": _value(
            identity.representative_role
        ),
        "ekeflicks_email": _value(identity.email),
        "ekeflicks_website": _value(identity.website),
    }


def full_contract_context(account):
    context = {}
    context.update(producer_contract_context(account))
    context.update(platform_contract_context())
    return context


PLATFORM_AGREEMENT_SNAPSHOT_MAP = {
    "ekeflicks_legal_name": "platform_legal_name",
    "ekeflicks_legal_form": "platform_legal_form",
    "ekeflicks_capital": "platform_capital",
    "ekeflicks_registered_office": "platform_registered_office",
    "ekeflicks_postal_code": "platform_postal_code",
    "ekeflicks_city": "platform_city",
    "ekeflicks_country": "platform_country",
    "ekeflicks_siret": "platform_siret",
    "ekeflicks_rcs": "platform_rcs",
    "ekeflicks_vat_number": "platform_vat_number",
    "ekeflicks_representative_name": "platform_representative_name",
    "ekeflicks_representative_role": "platform_representative_role",
    "ekeflicks_email": "platform_email",
    "ekeflicks_website": "platform_website",
}


def platform_agreement_snapshot_values():
    """
    Capture the currently active EKEFLICKS legal identity.

    The returned mapping uses ProducerAgreement field names.
    """
    context = platform_contract_context()

    return {
        field_name: _value(context[placeholder])
        for placeholder, field_name
        in PLATFORM_AGREEMENT_SNAPSHOT_MAP.items()
    }


def agreement_platform_contract_context(agreement):
    """
    Return the immutable EKEFLICKS identity stored on an agreement.

    This must be used after the agreement has been presented so later
    PlatformLegalIdentity changes cannot alter the legal document.
    """
    return {
        placeholder: _value(
            getattr(agreement, field_name, "")
        )
        for placeholder, field_name
        in PLATFORM_AGREEMENT_SNAPSHOT_MAP.items()
    }


def agreement_has_platform_snapshot(agreement):
    context = agreement_platform_contract_context(
        agreement
    )

    return all(
        context.values()
    )
