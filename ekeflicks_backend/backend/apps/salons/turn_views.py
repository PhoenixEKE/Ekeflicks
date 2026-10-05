from django.shortcuts import get_object_or_404

from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .models import Salon, SalonMember
from .turn_credentials import ice_server_configuration


class SalonIceServersView(APIView):
    permission_classes = (IsAuthenticated,)
    throttle_classes = (ScopedRateThrottle,)
    throttle_scope = "salon_ice_servers"

    def get(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
            status=Salon.STATUS_OPEN,
        )
        is_active_member = SalonMember.objects.filter(
            salon=salon,
            user=request.user,
            left_at__isnull=True,
        ).exists()
        if salon.host_id != request.user.pk and not is_active_member:
            raise PermissionDenied(
                "Only active salon members can request ICE server credentials."
            )

        return Response(ice_server_configuration(request.user.pk))
