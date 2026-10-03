PRODUCER_CONTRACT_PLACEHOLDERS = (
    "producer_legal_name",
    "producer_company_name",
    "producer_legal_form",
    "producer_country_code",
    "producer_address",
    "producer_city",
    "producer_registration_number",
    "producer_tax_number",
    "producer_representative_name",
    "producer_representative_role",
    "producer_email",
    "producer_phone",
)

EKEFLICKS_CONTRACT_PLACEHOLDERS = (
    "ekeflicks_legal_name",
    "ekeflicks_legal_form",
    "ekeflicks_capital",
    "ekeflicks_registered_office",
    "ekeflicks_postal_code",
    "ekeflicks_city",
    "ekeflicks_country",
    "ekeflicks_siret",
    "ekeflicks_rcs",
    "ekeflicks_vat_number",
    "ekeflicks_representative_name",
    "ekeflicks_representative_role",
    "ekeflicks_email",
    "ekeflicks_website",
    "ekeflicks_signature_datetime",
)

COMPENSATION_CONTRACT_PLACEHOLDERS = (
    "producer_rate_per_1000_views_eur",
    "producer_eligible_progress_percent",
    "producer_advertising_share_percent",
    "ekeflicks_advertising_share_percent",
)

ALL_CONTRACT_PLACEHOLDERS = (
    PRODUCER_CONTRACT_PLACEHOLDERS
    + EKEFLICKS_CONTRACT_PLACEHOLDERS
    + COMPENSATION_CONTRACT_PLACEHOLDERS
)
