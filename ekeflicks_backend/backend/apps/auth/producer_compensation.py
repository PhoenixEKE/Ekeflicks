from __future__ import annotations

import re
from datetime import datetime
from decimal import Decimal
from functools import lru_cache
from pathlib import Path

from django.db.models import Q
from django.utils import timezone

from core.models import ProducerAccount, ProducerAgreement, ProducerContractVersion


_DEFAULTS = {
    'rate_per_1000_views_eur': Decimal('1.500000'),
    'eligible_progress_percent': Decimal('70.00'),
    'advertising_share_percent': Decimal('60.00'),
}


def _normalize_decimal(value):
    if value is None:
        return None
    return Decimal(str(value).replace(',', '.'))


def _parse_cfa_amount(value):
    amount = Decimal(re.sub(r'[\s.]', '', str(value)))
    return (amount / Decimal('655.957')).quantize(Decimal('0.000001'))


def parse_contract_compensation(content):
    """Read historic commercial terms from the immutable contract text."""
    text = str(content or '')
    text = re.sub(
        r'mille\s*\(\s*1\s*000\s*\)\s*francs?\s*CFA BCEAO\s*\(FCFA\)',
        '1000 FCFA',
        text,
        flags=re.IGNORECASE,
    )
    rate = None
    rate_patterns = (
        r'\((\d{1,5}(?:[,.]\d{1,6})?)\s*€\)\s*(?:pour mille|pour 1\s*000)',
        r'(?:EUR|€)\s*(\d{1,5}(?:[,.]\d{1,6})?).{0,100}?(?:per 1,?000|per thousand)',
        r'(\d{1,5}(?:[,.]\d{1,6})?)\s*(?:EUR|€).{0,100}?(?:per 1,?000|per thousand)',
    )
    for pattern in rate_patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL)
        if match:
            rate = _normalize_decimal(match.group(1))
            break
    if rate is None:
        cfa_match = re.search(
            r'(\d{1,3}(?:[ .]\d{3})+|\d{1,7})\s*(?:FCFA|XOF).{0,100}(?:pour mille|pour 1\s*000|per 1,?000|per thousand)',
            text, flags=re.IGNORECASE | re.DOTALL,
        )
        if cfa_match:
            rate = _parse_cfa_amount(cfa_match.group(1))

    share = None
    for line in text.splitlines():
        if '%' not in line:
            continue
        if re.search(r'producteur|producer', line, re.IGNORECASE):
            match = re.search(r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%', line)
            if match:
                share = _normalize_decimal(match.group(1))
                break

    progress = None
    progress_patterns = (
        r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%[^\n.]{0,60}(?:du contenu|of the content)',
        r'(?:plus de|more than)\s*(\d{1,3}(?:[,.]\d{1,2})?)\s*%',
    )
    for pattern in progress_patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if match:
            progress = _normalize_decimal(match.group(1))
            break

    return {
        'rate_per_1000_views_eur': rate,
        'eligible_progress_percent': progress,
        'advertising_share_percent': share,
    }


@lru_cache(maxsize=64)
def _legacy_template_terms(version):
    template = (
        Path(__file__).resolve().parent
        / 'contract_templates'
        / f'contrat-producteur-ekeflicks-{version}.pdf'
    )
    if not template.exists():
        return {}
    try:
        from PyPDF2 import PdfReader

        text = '\n'.join(page.extract_text() or '' for page in PdfReader(str(template)).pages)
    except Exception:
        return {}
    return parse_contract_compensation(text)


def _setting_terms():
    from apps.analytics.services import revenue_settings

    setting = revenue_settings()
    return {
        'rate_per_1000_views_eur': Decimal(setting.rate_per_1000_views_eur),
        'eligible_progress_percent': Decimal(setting.eligible_progress_percent),
        'advertising_share_percent': Decimal(setting.advertising_share_percent),
    }


def _contract_version_terms(version):
    row = ProducerContractVersion.objects.filter(version=version).first()
    values = {
        'rate_per_1000_views_eur': row.rate_per_1000_views_eur if row else None,
        'eligible_progress_percent': row.eligible_progress_percent if row else None,
        'advertising_share_percent': row.advertising_share_percent if row else None,
    }
    parsed = parse_contract_compensation(row.canonical_content) if row else {}
    parsed = {
        key: parsed.get(key) or _legacy_template_terms(version).get(key)
        for key in _DEFAULTS
    }
    result = {}
    for key in _DEFAULTS:
        value = _normalize_decimal(values[key])
        result[key] = value if value is not None else parsed.get(key)
    return result, 'contract_version'


def latest_signed_agreement(producer, *, effective_at=None):
    account = producer if isinstance(producer, ProducerAccount) else None
    if account is None:
        account = ProducerAccount.objects.filter(user=producer).first()
    if account is None:
        return None

    queryset = account.agreements.filter(
        status__in=(ProducerAgreement.STATUS_SIGNED, ProducerAgreement.STATUS_SUPERSEDED),
        signed_at__isnull=False,
    )
    if effective_at is not None:
        day = effective_at.date() if isinstance(effective_at, datetime) else effective_at
        queryset = queryset.filter(
            Q(effective_date__lte=day)
            | Q(effective_date__isnull=True, signed_at__date__lte=day)
        )
    return queryset.order_by('-effective_date', '-signed_at', '-created_at').first()


def compensation_terms_for(producer, *, effective_at=None):
    """Return the signed agreement terms effective for one producer/date."""
    agreement = latest_signed_agreement(producer, effective_at=effective_at)
    fallback = _setting_terms()
    if agreement is None:
        return {**fallback, 'agreement': None, 'source': 'platform_default'}

    parsed, source = _contract_version_terms(agreement.contract_version)
    result = {}
    for key in _DEFAULTS:
        value = _normalize_decimal(getattr(agreement, key, None))
        if value is None:
            value = parsed.get(key)
        result[key] = value if value is not None else fallback[key]
    return {**result, 'agreement': agreement, 'source': agreement.compensation_terms_source or source}


def terms_for_new_agreement(account, *, contract_version, effective_at=None):
    previous = latest_signed_agreement(account, effective_at=effective_at)
    version = ProducerContractVersion.objects.filter(version=contract_version).first()
    amendment = bool(version and version.amends_compensation)

    if amendment:
        terms = {
            'rate_per_1000_views_eur': _normalize_decimal(version.rate_per_1000_views_eur),
            'eligible_progress_percent': _normalize_decimal(version.eligible_progress_percent),
            'advertising_share_percent': _normalize_decimal(version.advertising_share_percent),
        }
        source = 'signed_amendment'
    elif previous is not None:
        inherited = compensation_terms_for(account, effective_at=effective_at)
        terms = {key: inherited[key] for key in _DEFAULTS}
        source = 'carried_forward'
    else:
        terms, source = _contract_version_terms(contract_version)
        defaults = _setting_terms()
        terms = {
            key: terms[key] if terms.get(key) is not None else defaults[key]
            for key in _DEFAULTS
        }

    if any(terms.get(key) is None for key in _DEFAULTS):
        raise ValueError('Les conditions de rémunération du contrat sont incomplètes.')
    return {
        **terms,
        'previous_agreement': previous,
        'compensation_amendment': amendment,
        'compensation_terms_source': source,
    }
