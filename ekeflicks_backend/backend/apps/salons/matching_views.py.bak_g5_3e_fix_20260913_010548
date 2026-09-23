from django.shortcuts import get_object_or_404

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Salon
from .realtime_services import require_realtime_member
from .social_matching import match_users_for_salon


class SalonSocialMatchingView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request, pk):
        salon = get_object_or_404(
            Salon,
            pk=pk,
        )

        require_realtime_member(
            salon=salon,
            user=request.user,
        )

        raw_limit = request.query_params.get(
            "limit",
            "10",
        )

        try:
            limit = int(raw_limit)
        except (TypeError, ValueError):
            limit = 10

        matches = match_users_for_salon(
            salon=salon,
            requester=request.user,
            limit=limit,
        )

        payload = []

        for match in matches:
            profile = match.profile

            payload.append(
                {
                    "user_id": match.user.pk,
                    "profile_id": profile.pk,
                    "profile_name": profile.name,
                    "avatar_url": (
                        profile.avatar_url or ""
                    ),
                    "country_code": (
                        profile.country_code
                        or match.user.country_code
                        or ""
                    ),
                    "score": match.score,
                    "reasons": list(
                        match.reasons
                    ),
                    "common_genre_ids": list(
                        match.common_genre_ids
                    ),
                    "common_content_ids": list(
                        match.common_content_ids
                    ),
                }
            )

        return Response(
            {
                "salon_id": str(salon.pk),
                "count": len(payload),
                "matches": payload,
            }
        )
