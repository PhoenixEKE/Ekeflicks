from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.catalog.views import (
    ContentStatusViewSet,
    ContentViewSet,
    EmissionViewSet,
    EpisodeViewSet,
    GenreViewSet,
    SeasonViewSet,
)

router = DefaultRouter()
router.register('genres', GenreViewSet, basename='genre')
router.register('emissions', EmissionViewSet, basename='emission')
router.register('content-statuses', ContentStatusViewSet, basename='content-status')
router.register('contents', ContentViewSet, basename='content')
router.register('seasons', SeasonViewSet, basename='season')
router.register('episodes', EpisodeViewSet, basename='episode')

urlpatterns = [
    # Compatibility route for the original web application's home feed URL.
    path(
        'catalog/home/',
        ContentViewSet.as_view({'get': 'home'}),
        name='catalog-home',
    ),
    path('', include(router.urls)),
]
