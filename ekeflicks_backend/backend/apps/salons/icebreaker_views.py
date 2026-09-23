from django.shortcuts import get_object_or_404

from rest_framework.permissions import (
    IsAuthenticated,
)
from rest_framework.response import Response
from rest_framework.views import APIView

from .icebreakers import (
    build_salon_icebreakers,
)
from .models import Salon


class SalonIcebreakerView(APIView):
    permission_classes = (
        IsAuthenticated,
    )

    def get(self, request, pk):
        salon = get_object_or_404(
            Salon.objects.select_related(
                "content",
            ),
            pk=pk,
        )

        facilitation = (
            build_salon_icebreakers(
                salon=salon,
                user=request.user,
            )
        )

        return Response(
            {
                "salon_id": str(
                    salon.pk
                ),
                "version":
                    facilitation.version,
                "context_level":
                    facilitation.context_level,
                "icebreakers": [
                    {
                        "id": item.id,
                        "text": item.text,
                        "kind": item.kind,
                    }
                    for item
                    in facilitation.icebreakers
                ],
            }
        )
