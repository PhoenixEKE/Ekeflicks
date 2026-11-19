from decimal import Decimal
from django.db import migrations, models
import django.db.models.deletion


def align_contract_defaults(apps, schema_editor):
    Setting = apps.get_model('core', 'ProducerRevenueSetting')
    # Contract parity: 1 EUR = 655.957 XOF. Keep the configured per-view rate
    # aligned with 1,000 XOF per 1,000 eligible views.
    Setting.objects.filter(pk=1).update(
        rate_per_1000_views_eur=Decimal('1.524490'),
        minimum_payout_eur=Decimal('76.224509'),
    )


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0047_producer_finance_access'),
    ]
    operations = [
        migrations.AddField(
            model_name='producerrevenuesetting',
            name='advertising_share_percent',
            field=models.DecimalField(decimal_places=2, default=60, max_digits=5),
        ),
        migrations.AlterField(
            model_name='producerrevenuesetting',
            name='rate_per_1000_views_eur',
            field=models.DecimalField(decimal_places=6, default=1.524490, max_digits=10),
        ),
        migrations.AlterField(
            model_name='producerrevenuesetting',
            name='minimum_payout_eur',
            field=models.DecimalField(decimal_places=6, default=76.224509, max_digits=10),
        ),
        migrations.AlterField(
            model_name='producercontentview',
            name='amount_eur',
            field=models.DecimalField(decimal_places=9, default=0, max_digits=14),
        ),
        migrations.AlterField(
            model_name='producerpayoutrequest',
            name='amount_eur',
            field=models.DecimalField(decimal_places=6, default=0, max_digits=14),
        ),
        migrations.CreateModel(
            name='ProducerAdvertisingRevenue',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('period', models.DateField(db_index=True)),
                ('external_reference', models.CharField(blank=True, max_length=120)),
                ('net_revenue_eur', models.DecimalField(decimal_places=4, max_digits=14)),
                ('share_percent', models.DecimalField(decimal_places=2, default=60, max_digits=5)),
                ('producer_share_eur', models.DecimalField(decimal_places=4, default=0, max_digits=14)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('requested', 'Requested'), ('paid', 'Paid'), ('void', 'Void')], db_index=True, default='pending', max_length=20)),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='producer_advertising_earnings', to='core.content')),
                ('producer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='advertising_earnings', to='core.user')),
                ('payout_request', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='advertising_earnings', to='core.producerpayoutrequest')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'db_table': 'producer_advertising_revenues'},
        ),
        migrations.AddConstraint(
            model_name='produceradvertisingrevenue',
            constraint=models.UniqueConstraint(fields=('content', 'period', 'external_reference'), name='producer_ad_revenue_unique_ref'),
        ),
        migrations.AddConstraint(
            model_name='produceradvertisingrevenue',
            constraint=models.CheckConstraint(check=models.Q(('net_revenue_eur__gte', 0)), name='producer_ad_net_nonnegative'),
        ),
        migrations.AddConstraint(
            model_name='produceradvertisingrevenue',
            constraint=models.CheckConstraint(check=models.Q(('share_percent__gte', 0), ('share_percent__lte', 100), _connector='AND'), name='producer_ad_share_0_100'),
        ),
        migrations.RunPython(align_contract_defaults, migrations.RunPython.noop),
    ]
