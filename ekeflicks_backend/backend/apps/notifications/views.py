from django.core import signing
from django.shortcuts import get_object_or_404
from rest_framework import filters, mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.common.api import is_true
from apps.notifications.serializers import (
    NotificationPreferencesSerializer,
    NotificationSerializer,
    notification_preferences,
)
from core.models import Notification, User


class UnsubscribeViewSet(viewsets.ViewSet):
    permission_classes = [permissions.AllowAny]

    def create(self, request):
        token = request.data.get("token", "")
        try:
            user_id = signing.loads(
                token, salt="notification-unsubscribe", max_age=60 * 60 * 24 * 365
            )
        except signing.BadSignature:
            return Response(
                {"detail": "Lien de désabonnement invalide ou expiré."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user = get_object_or_404(User, pk=user_id, is_active=True)
        preferences = notification_preferences(user)
        preferences["email_enabled"] = False
        data = dict(user.preferences or {})
        data["notifications"] = preferences
        user.preferences = data
        user.save(update_fields=["preferences", "updated_at"])
        return Response({"email_enabled": False})


class NotificationViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["created_at", "sent_at"]
    ordering = ["-created_at"]

    def get_queryset(self):
        queryset = (
            Notification.objects.filter(user=self.request.user)
            .select_related("type")
            .order_by("-created_at")
        )
        if "is_read" in self.request.query_params:
            queryset = queryset.filter(
                is_read=is_true(self.request.query_params.get("is_read"))
            )
        return queryset

    @action(detail=True, methods=["post"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        serializer = self.get_serializer(notification)
        return Response(serializer.data)

    @action(detail=False, methods=["post"], url_path="mark-all-read")
    def mark_all_read(self, request):
        updated = self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({"updated": updated}, status=status.HTTP_200_OK)

    @action(detail=False, methods=["get", "patch"], url_path="preferences")
    def preferences(self, request):
        if request.method == "GET":
            return Response(notification_preferences(request.user))
        serializer = NotificationPreferencesSerializer(
            request.user,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(notification_preferences(request.user))
