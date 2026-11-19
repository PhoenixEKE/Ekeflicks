from django.shortcuts import get_object_or_404

from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from apps.recommendations.user_context import (
    resolve_active_profile,
)

from .social_models import SocialProfile
from .social_serializers import (
    OwnSocialProfileSerializer,
    PublicSocialProfileSerializer,
)


def get_or_create_social_profile(profile):
    social, _ = SocialProfile.objects.get_or_create(
        profile=profile,
        defaults={
            "display_name": profile.name,
            "is_discoverable": False,
        },
    )
    return social


class OwnSocialProfileView(
    generics.RetrieveUpdateAPIView
):
    permission_classes = (IsAuthenticated,)
    serializer_class = OwnSocialProfileSerializer

    def get_object(self):
        profile = resolve_active_profile(
            user=self.request.user,
        )

        return get_or_create_social_profile(
            profile
        )


class PublicSocialProfileView(
    generics.RetrieveAPIView
):
    permission_classes = (IsAuthenticated,)
    serializer_class = PublicSocialProfileSerializer

    def get_object(self):
        queryset = (
            SocialProfile.objects
            .select_related(
                "profile",
                "profile__user",
            )
            .filter(
                profile__is_active=True,
                profile__user__is_active=True,
                is_discoverable=True,
            )
        )

        return get_object_or_404(
            queryset,
            profile_id=self.kwargs["profile_id"],
        )


# ---------------------------------------------------------------------------
# G5-3G — Owner-controlled social safety actions
# ---------------------------------------------------------------------------

from django.db import IntegrityError
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .social_models import (
    SocialBlock,
    SocialMute,
    SocialReport,
)
from .social_safety import (
    ensure_social_reputation,
)
from .social_serializers import (
    SocialReportCreateSerializer,
    SocialReputationSerializer,
    SocialTargetSerializer,
)


def _own_social_profile(request):
    profile = resolve_active_profile(
        user=request.user,
    )

    return get_or_create_social_profile(
        profile
    )


def _target_social_profile(profile_id):
    return get_object_or_404(
        SocialProfile.objects.select_related(
            "profile",
            "profile__user",
        ),
        profile_id=profile_id,
        profile__is_active=True,
        profile__user__is_active=True,
    )


def _reject_self(owner, target):
    if owner.pk == target.pk:
        from rest_framework.exceptions import ValidationError

        raise ValidationError(
            {
                "profile_id":
                "A social profile cannot target itself."
            }
        )


class SocialBlockView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = SocialTargetSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        owner = _own_social_profile(request)
        target = _target_social_profile(
            serializer.validated_data["profile_id"]
        )
        _reject_self(owner, target)

        _, created = SocialBlock.objects.get_or_create(
            blocker=owner,
            blocked=target,
        )

        return Response(
            {
                "profile_id": str(target.profile_id),
                "blocked": True,
            },
            status=(
                status.HTTP_201_CREATED
                if created
                else status.HTTP_200_OK
            ),
        )

    def delete(self, request):
        serializer = SocialTargetSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        owner = _own_social_profile(request)
        target = _target_social_profile(
            serializer.validated_data["profile_id"]
        )
        _reject_self(owner, target)

        SocialBlock.objects.filter(
            blocker=owner,
            blocked=target,
        ).delete()

        return Response(
            {
                "profile_id": str(target.profile_id),
                "blocked": False,
            }
        )


class SocialMuteView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = SocialTargetSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        owner = _own_social_profile(request)
        target = _target_social_profile(
            serializer.validated_data["profile_id"]
        )
        _reject_self(owner, target)

        _, created = SocialMute.objects.get_or_create(
            muter=owner,
            muted=target,
        )

        return Response(
            {
                "profile_id": str(target.profile_id),
                "muted": True,
            },
            status=(
                status.HTTP_201_CREATED
                if created
                else status.HTTP_200_OK
            ),
        )

    def delete(self, request):
        serializer = SocialTargetSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        owner = _own_social_profile(request)
        target = _target_social_profile(
            serializer.validated_data["profile_id"]
        )
        _reject_self(owner, target)

        SocialMute.objects.filter(
            muter=owner,
            muted=target,
        ).delete()

        return Response(
            {
                "profile_id": str(target.profile_id),
                "muted": False,
            }
        )


class SocialReportView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = SocialReportCreateSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        owner = _own_social_profile(request)
        target = _target_social_profile(
            serializer.validated_data["profile_id"]
        )
        _reject_self(owner, target)

        report = SocialReport.objects.create(
            reporter=owner,
            reported=target,
            reason=serializer.validated_data["reason"],
            details=serializer.validated_data.get(
                "details",
                "",
            ).strip(),
        )

        return Response(
            {
                "id": report.pk,
                "profile_id": str(target.profile_id),
                "reason": report.reason,
                "created_at": report.created_at,
            },
            status=status.HTTP_201_CREATED,
        )


class OwnSocialReputationView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        owner = _own_social_profile(request)

        reputation = ensure_social_reputation(
            owner
        )

        serializer = SocialReputationSerializer(
            reputation
        )

        return Response(serializer.data)


class SocialModerationView(APIView):
    """
    Internal staff moderation endpoint.

    Public users must never be able to change moderation state.
    """

    permission_classes = [IsAuthenticated]

    def patch(self, request, profile_id):
        from rest_framework.exceptions import PermissionDenied

        from apps.profiles.social_models import SocialProfile
        from apps.profiles.social_moderation import (
            moderate_social_profile,
        )
        from apps.profiles.social_serializers import (
            SocialModerationSerializer,
            SocialModerationUpdateSerializer,
        )

        if not request.user.is_staff:
            raise PermissionDenied(
                "Staff moderation permission required."
            )

        target = get_object_or_404(
            SocialProfile.objects.select_related(
                "profile",
                "profile__user",
            ),
            profile_id=profile_id,
        )

        serializer = SocialModerationUpdateSerializer(
            data=request.data,
        )
        serializer.is_valid(
            raise_exception=True,
        )

        moderation, _ = moderate_social_profile(
            profile=target,
            status=serializer.validated_data["status"],
            reviewer=request.user,
            reason=serializer.validated_data.get(
                "reason",
                "",
            ),
        )

        return Response(
            SocialModerationSerializer(
                moderation
            ).data
        )


