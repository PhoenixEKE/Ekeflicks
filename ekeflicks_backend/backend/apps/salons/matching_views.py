from django.shortcuts import get_object_or_404

from rest_framework.permissions import (
    IsAuthenticated,
)
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.profiles.social_models import (
    SocialProfile,
)

from .matching_serializers import (
    SalonSocialMatchSerializer,
)
from .models import Salon
from .realtime_services import (
    require_realtime_member,
)
from .social_matching import (
    match_users_for_salon,
)


class SalonSocialMatchingView(APIView):
    permission_classes = (
        IsAuthenticated,
    )

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

        profile_ids = [
            match.profile.pk
            for match in matches
        ]

        social_by_profile = {
            social.profile_id: social
            for social in (
                SocialProfile.objects
                .select_related("profile")
                .filter(
                    profile_id__in=profile_ids,
                    is_discoverable=True,
                )
            )
        }

        payload = []

        for match in matches:
            social = social_by_profile.get(
                match.profile.pk
            )

            if social is None:
                continue

            payload.append(
                {
                    "user_id":
                        match.user.pk,

                    "profile_id":
                        match.profile.pk,

                    "display_name":
                        social.public_display_name,

                    "avatar_url":
                        match.profile.avatar_url
                        or "",

                    "score":
                        match.score,

                    "reasons":
                        list(match.reasons),
                }
            )

        serializer = (
            SalonSocialMatchSerializer(
                payload,
                many=True,
            )
        )

        return Response(
            {
                "salon_id":
                    str(salon.pk),

                "count":
                    len(serializer.data),

                "matches":
                    serializer.data,
            }
        )
