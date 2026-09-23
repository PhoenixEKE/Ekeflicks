from django.conf import settings
from django.shortcuts import get_object_or_404

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Salon
from .realtime_services import (
    create_realtime_ticket,
)


class SalonRealtimeTicketView(APIView):
    permission_classes = (
        IsAuthenticated,
    )

    def post(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
        )

        ticket = create_realtime_ticket(
            salon=salon,
            user=request.user,
        )

        return Response(
            {
                "ticket": ticket,
                "expires_in": int(
                    getattr(
                        settings,
                        "SALON_REALTIME_TICKET_TTL",
                        60,
                    )
                ),
                "websocket_path": (
                    f"/ws/salons/{salon.pk}/"
                ),
            }
        )
