from django.shortcuts import get_object_or_404

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView

from .social_connection_serializers import (
    SocialConnectionCreateSerializer,
    SocialConnectionSerializer,
)
from .social_connections import (
    accept_connection_request,
    accepted_connections_for,
    connection_queryset_for,
    create_connection_request,
    decline_connection_request,
    remove_connection,
    resolve_requester_social,
    resolve_target_social,
)


class SocialConnectionListCreateView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        social = resolve_requester_social(
            user=request.user,
        )

        queryset = connection_queryset_for(
            social_profile=social,
        )

        serializer = SocialConnectionSerializer(
            queryset,
            many=True,
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK,
        )

    def post(self, request):
        input_serializer = (
            SocialConnectionCreateSerializer(
                data=request.data,
            )
        )

        input_serializer.is_valid(
            raise_exception=True,
        )

        requester_social = resolve_requester_social(
            user=request.user,
        )

        target_social = resolve_target_social(
            profile_id=(
                input_serializer.validated_data[
                    "target_profile_id"
                ]
            ),
        )

        connection = create_connection_request(
            requester_social=requester_social,
            target_social=target_social,
        )

        return Response(
            SocialConnectionSerializer(
                connection
            ).data,
            status=status.HTTP_201_CREATED,
        )


class AcceptedSocialConnectionListView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        social = resolve_requester_social(
            user=request.user,
        )

        serializer = SocialConnectionSerializer(
            accepted_connections_for(
                social_profile=social,
            ),
            many=True,
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK,
        )


class SocialConnectionDecisionView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request, connection_id, action):
        social = resolve_requester_social(
            user=request.user,
        )

        connection = get_object_or_404(
            connection_queryset_for(
                social_profile=social,
            ),
            pk=connection_id,
        )

        if action == "accept":
            connection = accept_connection_request(
                connection=connection,
                actor_social=social,
            )

        elif action == "decline":
            connection = decline_connection_request(
                connection=connection,
                actor_social=social,
            )

        else:
            return Response(
                {
                    "detail":
                        "Unsupported connection action."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            SocialConnectionSerializer(
                connection
            ).data,
            status=status.HTTP_200_OK,
        )


class SocialConnectionDeleteView(APIView):
    permission_classes = (IsAuthenticated,)

    def delete(self, request, connection_id):
        social = resolve_requester_social(
            user=request.user,
        )

        connection = get_object_or_404(
            connection_queryset_for(
                social_profile=social,
            ),
            pk=connection_id,
        )

        remove_connection(
            connection=connection,
            actor_social=social,
        )

        return Response(
            status=status.HTTP_204_NO_CONTENT,
        )
