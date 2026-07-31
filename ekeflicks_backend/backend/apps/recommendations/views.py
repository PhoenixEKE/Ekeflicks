from rest_framework import filters, mixins, permissions, viewsets
from rest_framework.decorators import action
from rest_framework import exceptions, status
from rest_framework.response import Response

from apps.recommendations.engine import (
    engine_status,
    generate_recommendations,
    sync_profile_to_graph,
)
from apps.recommendations.serializers import RecommendationGenerateSerializer, RecommendationSerializer
from core.models import Profile, Recommendation


class RecommendationViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    serializer_class = RecommendationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['score', 'created_at']
    ordering = ['-score']

    def get_queryset(self):
        queryset = (
            Recommendation.objects.filter(profile__user=self.request.user)
            .select_related('profile', 'profile__type', 'content', 'content__status')
            .prefetch_related('content__genres', 'content__emissions')
        )
        profile_id = self.request.query_params.get('profile')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        return queryset

    def _get_profile(self, request, profile_id=None):
        queryset = Profile.objects.filter(user=request.user, is_active=True)
        requested_profile = profile_id or request.query_params.get('profile')
        if requested_profile:
            profile = queryset.filter(pk=requested_profile).first()
        else:
            profile = queryset.order_by('created_at').first()
        if not profile:
            raise exceptions.PermissionDenied('Aucun profil actif disponible.')
        return profile

    @action(detail=True, methods=['post'], url_path='mark-viewed')
    def mark_viewed(self, request, pk=None):
        recommendation = self.get_object()
        recommendation.is_viewed = True
        recommendation.save(update_fields=['is_viewed'])
        serializer = self.get_serializer(recommendation)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='engine-status')
    def engine_status(self, request):
        return Response(engine_status())

    @action(detail=False, methods=['post'], url_path='sync-graph')
    def sync_graph(self, request):
        serializer = RecommendationGenerateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile_id = (
            serializer.validated_data.get('profile_id')
            or serializer.validated_data.get('profile')
        )
        profile = self._get_profile(request, profile_id)
        result = sync_profile_to_graph(profile)
        return Response(result, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def generate(self, request):
        serializer = RecommendationGenerateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile_id = (
            serializer.validated_data.get('profile_id')
            or serializer.validated_data.get('profile')
        )
        profile = self._get_profile(request, profile_id)
        result = generate_recommendations(
            profile,
            limit=serializer.validated_data.get('limit'),
        )
        payload = {
            'engine': result['engine'],
            'profile_id': result['profile_id'],
            'count': result['count'],
            'recommendations': RecommendationSerializer(
                result['recommendations'],
                many=True,
                context=self.get_serializer_context(),
            ).data,
        }
        return Response(payload, status=status.HTTP_200_OK)
