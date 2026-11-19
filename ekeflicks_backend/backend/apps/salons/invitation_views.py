from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Q

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .invitation_serializers import (
    SalonInvitationCreateSerializer,
    SalonInvitationSerializer,
)
from .invitations import (
    accept_salon_invitation,
    cancel_salon_invitation,
    create_salon_invitation,
    decline_salon_invitation,
)
from .models import (
    Salon,
    SalonInvitation,
)


User = get_user_model()


def _validation_response(exc):
    detail = getattr(exc, "message_dict", None)

    if detail is None:
        detail = {
            "detail": getattr(
                exc,
                "messages",
                [str(exc)],
            )
        }

    return Response(
        detail,
        status=status.HTTP_400_BAD_REQUEST,
    )


class SalonInvitationListCreateView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request, salon_id):
        queryset = (
            SalonInvitation.objects
            .filter(salon_id=salon_id)
            .filter(
                Q(inviter=request.user)
                | Q(invitee=request.user)
            )
            .select_related(
                "salon",
                "inviter",
                "invitee",
            )
            .order_by("-created_at")
        )

        direction = request.query_params.get(
            "direction"
        )

        if direction == "sent":
            queryset = queryset.filter(
                inviter=request.user
            )
        elif direction == "received":
            queryset = queryset.filter(
                invitee=request.user
            )

        serializer = SalonInvitationSerializer(
            queryset,
            many=True,
        )

        return Response(serializer.data)

    def post(self, request, salon_id):
        serializer = SalonInvitationCreateSerializer(
            data=request.data
        )
        serializer.is_valid(
            raise_exception=True
        )

        try:
            salon = Salon.objects.get(
                pk=salon_id
            )
        except Salon.DoesNotExist:
            return Response(
                {"detail": "Salon not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        invitee = User.objects.get(
            pk=serializer.validated_data[
                "invitee_id"
            ]
        )

        try:
            invitation = create_salon_invitation(
                salon=salon,
                inviter=request.user,
                invitee=invitee,
            )
        except DjangoValidationError as exc:
            return _validation_response(exc)

        return Response(
            SalonInvitationSerializer(
                invitation
            ).data,
            status=status.HTTP_201_CREATED,
        )


class SalonInvitationDecisionView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request, invitation_id, action):
        try:
            invitation = SalonInvitation.objects.get(
                pk=invitation_id
            )
        except SalonInvitation.DoesNotExist:
            return Response(
                {"detail": "Invitation not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            if action == "accept":
                invitation, _membership = (
                    accept_salon_invitation(
                        invitation=invitation,
                        user=request.user,
                    )
                )

            elif action == "decline":
                invitation = decline_salon_invitation(
                    invitation=invitation,
                    user=request.user,
                )

            elif action == "cancel":
                invitation = cancel_salon_invitation(
                    invitation=invitation,
                    user=request.user,
                )

            else:
                return Response(
                    {"detail": "Unsupported action."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        except DjangoValidationError as exc:
            return _validation_response(exc)

        return Response(
            SalonInvitationSerializer(
                invitation
            ).data
        )
