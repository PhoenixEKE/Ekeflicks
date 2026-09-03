from core.models import SubscriptionPlanOffer


# UEMOA — Franc CFA BCEAO (XOF)
UEMOA_COUNTRIES = {
    'BJ',  # Bénin
    'BF',  # Burkina Faso
    'CI',  # Côte d'Ivoire
    'GW',  # Guinée-Bissau
    'ML',  # Mali
    'NE',  # Niger
    'SN',  # Sénégal
    'TG',  # Togo
}


# Afrique hors UEMOA
AFRICA_OTHER_COUNTRIES = {
    'DZ', 'AO', 'BW', 'BI', 'CM', 'CV', 'CF', 'TD',
    'KM', 'CG', 'CD', 'DJ', 'EG', 'GQ', 'ER', 'SZ',
    'ET', 'GA', 'GM', 'GH', 'GN', 'KE', 'LS', 'LR',
    'LY', 'MG', 'MW', 'MR', 'MU', 'MA', 'MZ', 'NA',
    'NG', 'RW', 'ST', 'SC', 'SL', 'SO', 'ZA', 'SS',
    'SD', 'TZ', 'TN', 'UG', 'ZM', 'ZW',
}


# États-Unis
USA_COUNTRIES = {
    'US',
}


# Europe
#
# Inclut :
# - Union européenne
# - EEE
# - Royaume-Uni
# - Suisse
# - Balkans
# - micro-États européens
# - Moldavie, Ukraine, Biélorussie
EUROPE_COUNTRIES = {
    'AL',  # Albanie
    'AD',  # Andorre
    'AT',  # Autriche
    'BY',  # Biélorussie
    'BE',  # Belgique
    'BA',  # Bosnie-Herzégovine
    'BG',  # Bulgarie
    'HR',  # Croatie
    'CY',  # Chypre
    'CZ',  # Tchéquie
    'DK',  # Danemark
    'EE',  # Estonie
    'FI',  # Finlande
    'FR',  # France
    'DE',  # Allemagne
    'GR',  # Grèce
    'HU',  # Hongrie
    'IS',  # Islande
    'IE',  # Irlande
    'IT',  # Italie
    'LV',  # Lettonie
    'LI',  # Liechtenstein
    'LT',  # Lituanie
    'LU',  # Luxembourg
    'MT',  # Malte
    'MD',  # Moldavie
    'MC',  # Monaco
    'ME',  # Monténégro
    'NL',  # Pays-Bas
    'MK',  # Macédoine du Nord
    'NO',  # Norvège
    'PL',  # Pologne
    'PT',  # Portugal
    'RO',  # Roumanie
    'SM',  # Saint-Marin
    'RS',  # Serbie
    'SK',  # Slovaquie
    'SI',  # Slovénie
    'ES',  # Espagne
    'SE',  # Suède
    'CH',  # Suisse
    'UA',  # Ukraine
    'GB',  # Royaume-Uni
    'VA',  # Vatican
}


def normalize_country_code(country_code):
    """
    Normalise un code pays ISO alpha-2.

    Les valeurs absentes, mal formées ou non alphabétiques
    retournent une chaîne vide et seront donc classées GLOBAL.
    """
    code = str(country_code or '').strip().upper()

    if len(code) != 2 or not code.isalpha():
        return ''

    return code


def resolve_market_zone(country_code):
    code = normalize_country_code(country_code)

    if code in UEMOA_COUNTRIES:
        return SubscriptionPlanOffer.ZONE_UEMOA

    if code in AFRICA_OTHER_COUNTRIES:
        return SubscriptionPlanOffer.ZONE_AFRICA_OTHER

    if code in USA_COUNTRIES:
        return SubscriptionPlanOffer.ZONE_USA

    if code in EUROPE_COUNTRIES:
        return SubscriptionPlanOffer.ZONE_EUROPE

    return SubscriptionPlanOffer.ZONE_GLOBAL


def resolve_plan_offer(plan, country_code):
    zone = resolve_market_zone(country_code)

    offer = (
        plan.regional_offers
        .filter(
            zone=zone,
            is_active=True,
        )
        .first()
    )

    if offer:
        return offer

    return (
        plan.regional_offers
        .filter(
            zone=SubscriptionPlanOffer.ZONE_GLOBAL,
            is_active=True,
        )
        .first()
    )
