from django.db.models import Avg
from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.playback.serializers import (
    CustomListSerializer,
    FavoriteSerializer,
    ListItemSerializer,
    RatingSerializer,
    ViewingSessionSerializer,
    WatchHistorySerializer,
)
from core.models import CustomList, Favorite, ListItem, Rating, ViewingSession, WatchHistory


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Favorite.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type', 'content', 'content__status')
            .prefetch_related('content__genres', 'content__emissions')
            .order_by('-created_at')
        )


class WatchHistoryViewSet(viewsets.ModelViewSet):
    serializer_class = WatchHistorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['updated_at', 'watched_at', 'progress']
    ordering = ['-updated_at']

    def get_queryset(self):
        queryset = (
            WatchHistory.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type', 'content', 'content__status', 'episode')
            .prefetch_related('content__genres', 'content__emissions')
        )
        profile_id = self.request.query_params.get('profile')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        return queryset

    @action(detail=False, methods=['get'], url_path='continue-watching')
    def continue_watching(self, request):
        queryset = self.get_queryset().filter(
            completed=False,
            progress__gt=0,
        ).order_by('-updated_at')
        limit = request.query_params.get('limit', 20)
        try:
            limit = max(1, min(int(limit), 50))
        except (TypeError, ValueError):
            limit = 20
        serializer = self.get_serializer(queryset[:limit], many=True)
        return Response(serializer.data)


class RatingViewSet(viewsets.ModelViewSet):
    serializer_class = RatingSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['rating', 'created_at', 'updated_at']
    ordering = ['-updated_at']

    def get_queryset(self):
        queryset = (
            Rating.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type', 'content', 'content__status')
            .prefetch_related('content__genres', 'content__emissions')
        )
        profile_id = self.request.query_params.get('profile')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        return queryset

    def _refresh_content_rating(self, content):
        aggregate = content.ratings.aggregate(avg=Avg('rating'))
        content.rating_avg = aggregate['avg'] or 0
        content.rating_count = content.ratings.count()
        content.save(update_fields=['rating_avg', 'rating_count', 'updated_at'])

    def perform_create(self, serializer):
        rating = serializer.save()
        self._refresh_content_rating(rating.content)

    def perform_update(self, serializer):
        rating = serializer.save()
        self._refresh_content_rating(rating.content)

    def perform_destroy(self, instance):
        content = instance.content
        instance.delete()
        self._refresh_content_rating(content)


class CustomListViewSet(viewsets.ModelViewSet):
    serializer_class = CustomListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = (
            CustomList.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type')
            .prefetch_related('items__content', 'items__content__genres', 'items__content__emissions')
            .order_by('-updated_at')
        )
        profile_id = self.request.query_params.get('profile')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        return queryset


class ListItemViewSet(viewsets.ModelViewSet):
    serializer_class = ListItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            ListItem.objects.filter(list__profile__user=self.request.user)
            .select_related('list', 'content', 'content__status')
            .prefetch_related('content__genres', 'content__emissions')
            .order_by('added_order', '-added_at')
        )


class ViewingSessionViewSet(viewsets.ModelViewSet):
    serializer_class = ViewingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['start_time', 'end_time', 'duration_watched']
    ordering = ['-start_time']

    def get_queryset(self):
        queryset = (
            ViewingSession.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type', 'content', 'content__status', 'episode')
            .prefetch_related('content__genres', 'content__emissions')
        )
        profile_id = self.request.query_params.get('profile')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        return queryset
