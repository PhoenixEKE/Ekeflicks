import uuid

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


def seed_revenue_defaults(apps, schema_editor):
    ProducerRevenueSetting = apps.get_model('core', 'ProducerRevenueSetting')
    ProducerCountryCurrency = apps.get_model('core', 'ProducerCountryCurrency')

    ProducerRevenueSetting.objects.get_or_create(
        pk=1,
        defaults={
            'remuneration_enabled': True,
            'eligible_progress_percent': 30,
            'rate_per_1000_views_eur': 1.5,
            'minimum_payout_eur': 0,
        },
    )

    cfa_xof = ['CI', 'SN', 'BF', 'ML', 'BJ', 'TG', 'NE', 'GW']
    cfa_xaf = ['CM', 'GA', 'CG', 'TD', 'CF', 'GQ']
    for country_code in cfa_xof:
        ProducerCountryCurrency.objects.get_or_create(
            country_code=country_code,
            defaults={'currency': 'XOF', 'eur_to_currency_rate': 655.957},
        )
    for country_code in cfa_xaf:
        ProducerCountryCurrency.objects.get_or_create(
            country_code=country_code,
            defaults={'currency': 'XAF', 'eur_to_currency_rate': 655.957},
        )


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('core', '0006_producer_workflow'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='producer_remuneration_enabled',
            field=models.BooleanField(default=True),
        ),
        migrations.CreateModel(
            name='AccountClosureRequest',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('request_type', models.CharField(choices=[('deactivate_account', 'Deactivate account'), ('delete_account', 'Delete account'), ('cancel_subscription', 'Cancel subscription')], max_length=30)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('cancelled', 'Cancelled'), ('processed', 'Processed')], default='pending', max_length=20)),
                ('reason', models.TextField(blank=True)),
                ('admin_reason', models.TextField(blank=True)),
                ('requested_for', models.DateTimeField(blank=True, null=True)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('processed_at', models.DateTimeField(blank=True, null=True)),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_closure_requests', to=settings.AUTH_USER_MODEL)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='closure_requests', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'account_closure_requests',
            },
        ),
        migrations.CreateModel(
            name='ProducerCountryCurrency',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('country_code', models.CharField(max_length=2, unique=True)),
                ('currency', models.CharField(default='EUR', max_length=3)),
                ('eur_to_currency_rate', models.DecimalField(decimal_places=6, default=1, max_digits=12)),
                ('is_active', models.BooleanField(default=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'producer_country_currencies',
                'ordering': ['country_code'],
            },
        ),
        migrations.CreateModel(
            name='ProducerPayoutRequest',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('amount_eur', models.DecimalField(decimal_places=4, default=0, max_digits=12)),
                ('currency', models.CharField(default='EUR', max_length=3)),
                ('amount_local', models.DecimalField(decimal_places=4, default=0, max_digits=12)),
                ('eligible_views', models.PositiveIntegerField(default=0)),
                ('payout_method', models.CharField(blank=True, max_length=50)),
                ('payout_account', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('pending', 'En attente'), ('approved', 'Valide'), ('rejected', 'Refuse'), ('paid', 'Paye'), ('cancelled', 'Annule')], default='pending', max_length=20)),
                ('producer_note', models.TextField(blank=True)),
                ('admin_reason', models.TextField(blank=True)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('paid_at', models.DateTimeField(blank=True, null=True)),
                ('producer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='payout_requests', to=settings.AUTH_USER_MODEL)),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_payout_requests', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'producer_payout_requests',
            },
        ),
        migrations.CreateModel(
            name='ProducerRevenueSetting',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('remuneration_enabled', models.BooleanField(default=True)),
                ('eligible_progress_percent', models.DecimalField(decimal_places=2, default=30, max_digits=5)),
                ('rate_per_1000_views_eur', models.DecimalField(decimal_places=4, default=1.5, max_digits=10)),
                ('minimum_payout_eur', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'producer_revenue_settings',
            },
        ),
        migrations.CreateModel(
            name='ProducerContentView',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('watched_seconds', models.PositiveIntegerField(default=0)),
                ('total_seconds', models.PositiveIntegerField(default=0)),
                ('progress_percent', models.DecimalField(decimal_places=2, default=0, max_digits=5)),
                ('viewer_country_code', models.CharField(blank=True, max_length=2)),
                ('amount_eur', models.DecimalField(decimal_places=6, default=0, max_digits=12)),
                ('currency', models.CharField(default='EUR', max_length=3)),
                ('amount_local', models.DecimalField(decimal_places=6, default=0, max_digits=12)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('requested', 'Requested'), ('paid', 'Paid'), ('void', 'Void')], default='pending', max_length=20)),
                ('counted_at', models.DateTimeField(auto_now_add=True)),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='producer_views', to='core.content')),
                ('episode', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='core.episode')),
                ('payout_request', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='producer_views', to='core.producerpayoutrequest')),
                ('producer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='producer_views', to=settings.AUTH_USER_MODEL)),
                ('viewing_session', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='producer_view', to='core.viewingsession')),
            ],
            options={
                'db_table': 'producer_content_views',
            },
        ),
        migrations.AddIndex(
            model_name='accountclosurerequest',
            index=models.Index(fields=['user', 'status'], name='account_clo_user_id_3bf80d_idx'),
        ),
        migrations.AddIndex(
            model_name='accountclosurerequest',
            index=models.Index(fields=['request_type', 'status'], name='account_clo_request_69c399_idx'),
        ),
        migrations.AddIndex(
            model_name='accountclosurerequest',
            index=models.Index(fields=['requested_for'], name='account_clo_request_86be0b_idx'),
        ),
        migrations.AddIndex(
            model_name='producerpayoutrequest',
            index=models.Index(fields=['producer', 'status'], name='producer_pa_produce_f72580_idx'),
        ),
        migrations.AddIndex(
            model_name='producerpayoutrequest',
            index=models.Index(fields=['status', 'created_at'], name='producer_pa_status_6d50f9_idx'),
        ),
        migrations.AddIndex(
            model_name='producercontentview',
            index=models.Index(fields=['producer', 'status'], name='producer_co_produce_37c318_idx'),
        ),
        migrations.AddIndex(
            model_name='producercontentview',
            index=models.Index(fields=['content', 'counted_at'], name='producer_co_content_6a7800_idx'),
        ),
        migrations.AddIndex(
            model_name='producercontentview',
            index=models.Index(fields=['viewer_country_code', 'counted_at'], name='producer_co_viewer__299219_idx'),
        ),
        migrations.RunPython(seed_revenue_defaults, migrations.RunPython.noop),
    ]
