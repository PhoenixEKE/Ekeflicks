from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.analytics.serializers import (
    DailyStatSerializer,
    ProducerContentViewSerializer,
    ProducerCountryCurrencySerializer,
    ProducerRevenueSettingSerializer,
)
from apps.analytics.services import (
    clickhouse_status,
    dashboard_summary,
    revenue_settings,
    views_by_country,
    views_by_minute,
)
from core.models import DailyStat, ProducerContentView, ProducerCountryCurrency, ProducerRevenueSetting


class DailyStatViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = DailyStat.objects.all().order_by('-stat_date')
    serializer_class = DailyStatSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['stat_date', 'active_users', 'total_views', 'revenue']
    ordering = ['-stat_date']

    def get_permissions(self):
        if self.action in {'dashboard', 'views_by_minute', 'views_by_country', 'clickhouse_status'}:
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        return Response(dashboard_summary(request))

    @action(detail=False, methods=['get'], url_path='views-by-minute')
    def views_by_minute(self, request):
        return Response({'results': views_by_minute(request)})

    @action(detail=False, methods=['get'], url_path='views-by-country')
    def views_by_country(self, request):
        return Response({'results': views_by_country(request)})

    @action(detail=False, methods=['get'], url_path='clickhouse-status')
    def clickhouse_status(self, request):
        return Response(clickhouse_status())


class ProducerRevenueSettingViewSet(viewsets.ModelViewSet):
    serializer_class = ProducerRevenueSettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        revenue_settings()
        return ProducerRevenueSetting.objects.all().order_by('id')

    @action(detail=False, methods=['get', 'patch'])
    def current(self, request):
        setting = revenue_settings()
        if request.method.lower() == 'patch':
            serializer = self.get_serializer(setting, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        return Response(self.get_serializer(setting).data)


class ProducerCountryCurrencyViewSet(viewsets.ModelViewSet):
    queryset = ProducerCountryCurrency.objects.all().order_by('country_code')
    serializer_class = ProducerCountryCurrencySerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['country_code', 'currency']
    ordering_fields = ['country_code', 'currency', 'updated_at']
    ordering = ['country_code']


class ProducerContentViewViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ProducerContentViewSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['counted_at', 'amount_eur', 'progress_percent']
    ordering = ['-counted_at']

    def get_queryset(self):
        queryset = (
            ProducerContentView.objects.select_related('producer', 'content', 'episode', 'viewing_session')
            .order_by('-counted_at')
        )
        if not self.request.user.is_staff:
            queryset = queryset.filter(producer=self.request.user)
        status_name = self.request.query_params.get('status')
        content_id = self.request.query_params.get('content')
        if status_name:
            queryset = queryset.filter(status=status_name)
        if content_id:
            queryset = queryset.filter(content_id=content_id)
        return queryset
