import re
from decimal import Decimal
from pathlib import Path

from django.db import migrations, models
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
        return {key: Decimal(str(values[key])) if values[key] is not None else defaults[key] for key in defaults}

    by_account = {}
    for agreement in Agreement.objects.filter(signed_at__isnull=False).order_by('producer_account_id', 'signed_at', 'created_at'):
        terms = extract(agreement.contract_version)
        Agreement.objects.filter(pk=agreement.pk).update(
            rate_per_1000_views_eur=terms['rate_per_1000_views_eur'],
            eligible_progress_percent=terms['eligible_progress_percent'],
            advertising_share_percent=terms['advertising_share_percent'],
            compensation_terms_source='backfilled_contract_text',
            previous_agreement_id=by_account.get(agreement.producer_account_id),
        )
        by_account[agreement.producer_account_id] = agreement.pk

    for view in View.objects.select_related('producer').all().iterator():
        agreement = Agreement.objects.filter(
            producer_account__user_id=view.producer_id,
            signed_at__isnull=False,
        ).filter(
            models.Q(effective_date__lte=view.counted_at.date())
            | models.Q(effective_date__isnull=True, signed_at__date__lte=view.counted_at.date())
        ).order_by('-effective_date', '-signed_at').first()
        terms = extract(agreement.contract_version) if agreement else defaults
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
        ).order_by('-effective_date', '-signed_at').first()
        if agreement:
            AdRevenue.objects.filter(pk=row.pk).update(contract_agreement_id=agreement.pk)


class Migration(migrations.Migration):
    dependencies = [('core', '0053_producer_demo_earnings_and_contract_rules')]

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
