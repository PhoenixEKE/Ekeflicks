from decimal import Decimal
from django.db import migrations, models
import django.db.models.deletion


def align_final_contract_defaults(apps, schema_editor):
    Setting = apps.get_model('core', 'ProducerRevenueSetting')
    # These values are the preceding FCFA-based contract defaults.
    Setting.objects.filter(eligible_progress_percent=Decimal('30.00')).update(
        eligible_progress_percent=Decimal('70.00'),
    )
    Setting.objects.filter(rate_per_1000_views_eur=Decimal('1.524490')).update(
        rate_per_1000_views_eur=Decimal('1.500000'),
    )
    Setting.objects.filter(minimum_payout_eur=Decimal('76.224509')).update(
        minimum_payout_eur=Decimal('75.000000'),
    )


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0052_frequently_asked_questions'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProducerDemoEarning',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('seed_key', models.CharField(db_index=True, max_length=80)),
                ('period', models.DateField(db_index=True)),
                ('eligible_views', models.PositiveIntegerField(default=0)),
                ('view_revenue_eur', models.DecimalField(decimal_places=9, default=0, max_digits=14)),
                ('advertising_net_revenue_eur', models.DecimalField(decimal_places=4, default=0, max_digits=14)),
                ('advertising_share_percent', models.DecimalField(decimal_places=2, default=60, max_digits=5)),
                ('advertising_share_eur', models.DecimalField(decimal_places=4, default=0, max_digits=14)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='producer_demo_earnings', to='core.content')),
                ('producer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='demo_earnings', to='core.user')),
            ],
            options={'db_table': 'producer_demo_earnings'},
        ),
        migrations.AddConstraint(
            model_name='producerdemoearning',
            constraint=models.UniqueConstraint(fields=('producer', 'content', 'seed_key'), name='producer_demo_earning_unique_seed'),
        ),
        migrations.AddConstraint(
            model_name='producerdemoearning',
            constraint=models.CheckConstraint(
                check=models.Q(('view_revenue_eur__gte', 0), ('advertising_net_revenue_eur__gte', 0), _connector='AND'),
                name='producer_demo_earning_nonnegative',
            ),
        ),
        migrations.AddConstraint(
            model_name='producerdemoearning',
            constraint=models.CheckConstraint(
                check=models.Q(('advertising_share_percent__gte', 0), ('advertising_share_percent__lte', 100), _connector='AND'),
                name='producer_demo_share_0_100',
            ),
        ),
        migrations.AlterField(
            model_name='producerrevenuesetting',
            name='eligible_progress_percent',
            field=models.DecimalField(decimal_places=2, default=70, max_digits=5),
        ),
        migrations.AlterField(
            model_name='producerrevenuesetting',
            name='rate_per_1000_views_eur',
            field=models.DecimalField(decimal_places=6, default=1.5, max_digits=10),
        ),
        migrations.AlterField(
            model_name='producerrevenuesetting',
            name='minimum_payout_eur',
            field=models.DecimalField(decimal_places=6, default=75, max_digits=10),
        ),
        migrations.RunPython(align_final_contract_defaults, migrations.RunPython.noop),
    ]
