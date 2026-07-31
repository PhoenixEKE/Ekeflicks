from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.playback.views import (
    CustomListViewSet,
    FavoriteViewSet,
    ListItemViewSet,
    RatingViewSet,
    ViewingSessionViewSet,
    WatchHistoryViewSet,
)

router = DefaultRouter()
router.register('favorites', FavoriteViewSet, basename='favorite')
router.register('watch-history', WatchHistoryViewSet, basename='watch-history')
router.register('ratings', RatingViewSet, basename='rating')
router.register('lists', CustomListViewSet, basename='custom-list')
router.register('list-items', ListItemViewSet, basename='list-item')
router.register('viewing-sessions', ViewingSessionViewSet, basename='viewing-session')

urlpatterns = [
    path('', include(router.urls)),
]
