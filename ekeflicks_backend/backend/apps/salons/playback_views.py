from django.shortcuts import get_object_or_404

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Salon
from .playback_serializers import (
    SalonPlaybackStateSerializer,
    SalonPlaybackUpdateSerializer,
)
from .playback_services import (
    get_playback_state,
    update_playback_state,
)


class SalonPlaybackView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
        )

        state = get_playback_state(
            salon=salon,
            user=request.user,
        )

        return Response(
            SalonPlaybackStateSerializer(state).data
        )

    def patch(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
        )

        serializer = SalonPlaybackUpdateSerializer(
            data=request.data,
        )
        serializer.is_valid(
            raise_exception=True,
        )

        state = update_playback_state(
            salon=salon,
            user=request.user,
            **serializer.validated_data,
        )

        return Response(
            SalonPlaybackStateSerializer(state).data
        )


class SalonResyncView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
        )

        state = get_playback_state(
            salon=salon,
            user=request.user,
        )

        return Response(
            SalonPlaybackStateSerializer(state).data
        )
