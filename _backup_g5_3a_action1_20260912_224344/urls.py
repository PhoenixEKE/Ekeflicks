from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.urls import path, include
from drf_yasg.views import get_schema_view
from rest_framework import permissions
from apps.common.avatar_detail_views import AvatarDetailView
from apps.common.avatar_views import AvatarListView
from apps.common.cdn_views import cdn_media
from config.schema import API_INFO


schema_view = get_schema_view(
    API_INFO,
    public=True,
    permission_classes=[permissions.AllowAny],
)


def health_check(_request):
    return JsonResponse({'status': 'ok', 'service': 'ekeflicks-backend'})


urlpatterns = [
    path('', health_check, name='health_check'),
    path('health/', health_check, name='health'),
    path('cdn/<path:media_path>', cdn_media, name='cdn-media'),
    path('admin/', admin.site.urls),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('openapi.json', schema_view.without_ui(cache_timeout=0), name='openapi-json'),
    path('api/v1/auth/', include('apps.auth.urls')),
    path('api/v1/admin/', include('apps.admin_api.urls')),
    path('api/v1/avatars/', AvatarListView.as_view(), name='avatar-list'),
    path(
        'api/v1/avatars/<path:avatar_path>/',
        AvatarDetailView.as_view(),
        name='avatar-detail',
    ),
    path('api/v1/', include('apps.catalog.urls')),
    path('api/v1/', include('apps.profiles.urls')),
    path('api/v1/', include('apps.playback.urls')),
    path('api/v1/', include('apps.billing.urls')),
    path('api/v1/', include('apps.recommendations.urls')),
    path('api/v1/', include('apps.notifications.urls')),
    path('api/v1/', include('apps.analytics.urls')),
    path('api/v1/', include('apps.streaming.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
