import re
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from django.db import migrations, models
from django.db.models import DateField
from django.db.models.functions import Coalesce, TruncDate
import django.db.models.deletion


def backfill_contract_terms(apps, schema_editor):
    Agreement = apps.get_model('core', 'ProducerAgreement')
    ContractVersion = apps.get_model('core', 'ProducerContractVersion')
    RevenueSetting = apps.get_model('core', 'ProducerRevenueSetting')
    View = apps.get_model('core', 'ProducerContentView')
    AdRevenue = apps.get_model('core', 'ProducerAdvertisingRevenue')
    setting = RevenueSetting.objects.filter(pk=1).first()
    defaults = {
        'rate_per_1000_views_eur': Decimal(str(setting.rate_per_1000_views_eur if setting else '1.500000')),
        'eligible_progress_percent': Decimal(str(setting.eligible_progress_percent if setting else '70.00')),
        'advertising_share_percent': Decimal(str(setting.advertising_share_percent if setting else '60.00')),
    }

    def extract(version):
        row = ContractVersion.objects.filter(version=version).first()
        text = row.canonical_content if row else ''
        text = re.sub(
            r'mille\s*\(\s*1\s*000\s*\)\s*francs?\s*CFA BCEAO\s*\(FCFA\)',
            '1000 FCFA',
            text,
            flags=re.IGNORECASE,
        )
        values = {
            key: getattr(row, key, None) if row else None
            for key in defaults
        }
        if values['rate_per_1000_views_eur'] is None:
            match = re.search(r'\((\d{1,5}(?:[,.]\d{1,6})?)\s*€\)\s*(?:pour mille|pour 1\s*000)', text, re.I)
            if match:
                values['rate_per_1000_views_eur'] = Decimal(match.group(1).replace(',', '.'))
        if values['rate_per_1000_views_eur'] is None:
            cfa_match = re.search(
                r'(\d{1,3}(?:[ .]\d{3})+|\d{1,7})\s*(?:FCFA|XOF).{0,100}(?:pour mille|pour 1\s*000|per 1,?000|per thousand)',
                text,
                re.I | re.S,
            )
            if cfa_match:
                values['rate_per_1000_views_eur'] = (
                    Decimal(re.sub(r'[\s.]', '', cfa_match.group(1)))
                    / Decimal('655.957')
                ).quantize(Decimal('0.000001'))
        if values['eligible_progress_percent'] is None:
            match = re.search(r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%[^\n.]{0,60}(?:du contenu|of the content)', text, re.I)
            if match:
                values['eligible_progress_percent'] = Decimal(match.group(1).replace(',', '.'))
        if values['advertising_share_percent'] is None:
            for line in text.splitlines():
                if '%' in line and re.search(r'producteur|producer', line, re.I):
                    match = re.search(r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%', line)
                    if match:
                        values['advertising_share_percent'] = Decimal(match.group(1).replace(',', '.'))
                        break
        if any(values[key] is None for key in defaults):
            template = (
                Path(__file__).resolve().parents[2]
                / 'apps' / 'auth' / 'contract_templates'
                / f'contrat-producteur-ekeflicks-{version}.pdf'
            )
            if template.exists():
                try:
                    from PyPDF2 import PdfReader
                    text += '\n' + '\n'.join(
                        page.extract_text() or ''
                        for page in PdfReader(str(template)).pages
                    )
                except Exception:
                    pass
                text = re.sub(
                    r'mille\s*\(\s*1\s*000\s*\)\s*francs?\s*CFA BCEAO\s*\(FCFA\)',
                    '1000 FCFA',
                    text,
                    flags=re.IGNORECASE,
                )
                if values['rate_per_1000_views_eur'] is None:
                    match = re.search(r'\((\d{1,5}(?:[,.]\d{1,6})?)\s*€\)\s*(?:pour mille|pour 1\s*000)', text, re.I)
                    if match:
                        values['rate_per_1000_views_eur'] = Decimal(match.group(1).replace(',', '.'))
                    else:
                        match = re.search(r'(\d{1,3}(?:[ .]\d{3})+|\d{1,7})\s*(?:FCFA|XOF).{0,100}(?:pour mille|pour 1\s*000|per 1,?000|per thousand)', text, re.I | re.S)
                        if match:
                            values['rate_per_1000_views_eur'] = (
                                Decimal(re.sub(r'[\s.]', '', match.group(1))) / Decimal('655.957')
                            ).quantize(Decimal('0.000001'))
                if values['eligible_progress_percent'] is None:
                    match = re.search(r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%[^\n.]{0,60}(?:du contenu|of the content)', text, re.I)
                    if match:
                        values['eligible_progress_percent'] = Decimal(match.group(1).replace(',', '.'))
                if values['advertising_share_percent'] is None:
                    for line in text.splitlines():
                        if '%' in line and re.search(r'producteur|producer', line, re.I):
                            match = re.search(r'(\d{1,3}(?:[,.]\d{1,2})?)\s*%', line)
                            if match:
                                values['advertising_share_percent'] = Decimal(match.group(1).replace(',', '.'))
                                break
        return {key: Decimal(str(values[key])) if values[key] is not None else None for key in defaults}

    by_account = {}
    terms_by_account = {}
    agreements = Agreement.objects.filter(
        signed_at__isnull=False,
    ).order_by('producer_account_id', 'signed_at', 'created_at')
    for agreement in agreements:
        account_id = agreement.producer_account_id
        previous_id = by_account.get(account_id)
        previous_terms = terms_by_account.get(account_id)
        version = ContractVersion.objects.filter(
            version=agreement.contract_version,
        ).first()
        parsed_terms = extract(agreement.contract_version)
        text_changed_terms = bool(
            previous_terms
            and any(
                parsed_terms[key] is not None
                and parsed_terms[key] != previous_terms[key]
                for key in defaults
            )
        )
        compensation_amendment = bool(
            (version and version.amends_compensation)
            or text_changed_terms
        )

        if previous_terms and not compensation_amendment:
            # New legal text without a compensation amendment keeps the
            # producer's previous signed commercial terms.
            terms = dict(previous_terms)
            source = 'carried_forward'
        else:
            # A newly signed amendment can change only one commercial term;
            # unspecified values continue from the previous agreement.
            terms = {
                key: (
                    parsed_terms[key]
                    if parsed_terms[key] is not None
                    else previous_terms[key]
                    if previous_terms
                    else defaults[key]
                )
                for key in defaults
            }
            source = (
                'backfilled_contract_text'
                if any(value is not None for value in parsed_terms.values())
                else 'platform_default'
            )

        Agreement.objects.filter(pk=agreement.pk).update(
            rate_per_1000_views_eur=terms['rate_per_1000_views_eur'],
            eligible_progress_percent=terms['eligible_progress_percent'],
            advertising_share_percent=terms['advertising_share_percent'],
            compensation_amendment=compensation_amendment,
            compensation_terms_source=source,
            previous_agreement_id=previous_id,
        )
        by_account[account_id] = agreement.pk
        terms_by_account[account_id] = terms

    for view in View.objects.all().iterator():
        agreement = Agreement.objects.filter(
            producer_account__user_id=view.producer_id,
            signed_at__isnull=False,
        ).filter(
            models.Q(effective_date__lte=view.counted_at.date())
            | models.Q(effective_date__isnull=True, signed_at__date__lte=view.counted_at.date())
        ).annotate(
            _effective_on=Coalesce(
                'effective_date',
                TruncDate('signed_at'),
                output_field=DateField(),
            )
        ).order_by('-_effective_on', '-signed_at').first()
        terms = {
            'rate_per_1000_views_eur': (
                agreement.rate_per_1000_views_eur
                if agreement and agreement.rate_per_1000_views_eur is not None
                else defaults['rate_per_1000_views_eur']
            ),
            'eligible_progress_percent': (
                agreement.eligible_progress_percent
                if agreement and agreement.eligible_progress_percent is not None
                else defaults['eligible_progress_percent']
            ),
        }
        View.objects.filter(pk=view.pk).update(
            contract_agreement_id=agreement.pk if agreement else None,
            rate_per_1000_views_eur=terms['rate_per_1000_views_eur'],
            eligible_progress_percent=terms['eligible_progress_percent'],
        )

    for row in AdRevenue.objects.all().iterator():
        agreement = Agreement.objects.filter(
            producer_account__user_id=row.producer_id,
            signed_at__isnull=False,
        ).filter(
            models.Q(effective_date__lte=row.period)
            | models.Q(effective_date__isnull=True, signed_at__date__lte=row.period)
        ).annotate(
            _effective_on=Coalesce(
                'effective_date',
                TruncDate('signed_at'),
                output_field=DateField(),
            )
        ).order_by('-_effective_on', '-signed_at').first()
        updates = {'contract_agreement_id': agreement.pk if agreement else None}
        # Pending advertising earnings are still payable, so align them with
        # the agreement active for the revenue period. Preserve requested and
        # paid payout snapshots.
        if agreement and row.status == 'pending':
            share_percent = agreement.advertising_share_percent
            if share_percent is not None:
                producer_share = (
                    Decimal(row.net_revenue_eur)
                    * Decimal(share_percent)
                    / Decimal('100')
                ).quantize(Decimal('0.0001'), rounding=ROUND_HALF_UP)
                updates.update({
                    'share_percent': share_percent,
                    'producer_share_eur': producer_share,
                })
        AdRevenue.objects.filter(pk=row.pk).update(**updates)



class Migration(migrations.Migration):
    dependencies = [('core', '0054_video_asset_drm_metadata')]

    operations = [
        migrations.AddField('producercontractversion', 'amends_compensation', models.BooleanField(default=False)),
        migrations.AddField('producercontractversion', 'rate_per_1000_views_eur', models.DecimalField(blank=True, decimal_places=6, max_digits=10, null=True)),
        migrations.AddField('producercontractversion', 'eligible_progress_percent', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
        migrations.AddField('producercontractversion', 'advertising_share_percent', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
        migrations.AddField('produceragreement', 'previous_agreement', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='successor_agreements', to='core.produceragreement')),
        migrations.AddField('produceragreement', 'compensation_amendment', models.BooleanField(default=False)),
        migrations.AddField('produceragreement', 'compensation_terms_source', models.CharField(blank=True, max_length=32)),
        migrations.AddField('produceragreement', 'rate_per_1000_views_eur', models.DecimalField(blank=True, decimal_places=6, max_digits=10, null=True)),
        migrations.AddField('produceragreement', 'eligible_progress_percent', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
        migrations.AddField('produceragreement', 'advertising_share_percent', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
        migrations.AddField('producercontentview', 'contract_agreement', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='eligible_views', to='core.produceragreement')),
        migrations.AddField('producercontentview', 'rate_per_1000_views_eur', models.DecimalField(decimal_places=6, default=0, max_digits=10)),
        migrations.AddField('producercontentview', 'eligible_progress_percent', models.DecimalField(decimal_places=2, default=70, max_digits=5)),
        migrations.AddField('produceradvertisingrevenue', 'contract_agreement', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='advertising_revenues', to='core.produceragreement')),
        migrations.RunPython(backfill_contract_terms, migrations.RunPython.noop),
    ]
