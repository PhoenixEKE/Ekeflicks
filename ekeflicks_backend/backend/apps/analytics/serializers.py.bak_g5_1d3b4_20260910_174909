from rest_framework import serializers

from core.models import DailyStat, ProducerContentView, ProducerCountryCurrency, ProducerRevenueSetting


class DailyStatSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyStat
        fields = [
            'id',
            'stat_date',
            'total_users',
            'active_users',
            'total_views',
            'total_watch_time',
            'new_subscriptions',
            'revenue',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class ProducerRevenueSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProducerRevenueSetting
        fields = [
            'id',
            'remuneration_enabled',
            'eligible_progress_percent',
            'rate_per_1000_views_eur',
            'minimum_payout_eur',
            'updated_at',
        ]
        read_only_fields = ['id', 'updated_at']


class ProducerCountryCurrencySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProducerCountryCurrency
        fields = [
            'id',
            'country_code',
            'currency',
            'eur_to_currency_rate',
            'is_active',
            'updated_at',
        ]
        read_only_fields = ['id', 'updated_at']


class ProducerContentViewSerializer(serializers.ModelSerializer):
    producer_email = serializers.EmailField(source='producer.email', read_only=True)
    content_title = serializers.CharField(source='content.title', read_only=True)

    class Meta:
        model = ProducerContentView
        fields = [
            'id',
            'producer',
            'producer_email',
            'content',
            'content_title',
            'episode',
            'viewing_session',
            'watched_seconds',
            'total_seconds',
            'progress_percent',
            'viewer_country_code',
            'amount_eur',
            'currency',
            'amount_local',
            'status',
            'counted_at',
        ]
        read_only_fields = fields
