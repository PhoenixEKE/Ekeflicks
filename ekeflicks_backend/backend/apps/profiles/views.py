from rest_framework import filters, permissions, viewsets

from apps.common.permissions import IsAdminOrReadOnly
from apps.profiles.serializers import ProfileSerializer, ProfileTypeSerializer
from core.models import Profile, ProfileType


class ProfileTypeViewSet(viewsets.ModelViewSet):
    queryset = ProfileType.objects.all().order_by('name')
    serializer_class = ProfileTypeSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name']
    ordering = ['name']


class ProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Profile.objects.filter(user=self.request.user)
            .select_related('type')
            .order_by('-is_active', 'created_at')
        )

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=['is_active', 'updated_at'])
