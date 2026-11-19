from pathlib import PurePosixPath

from django.core.files.storage import storages
from django.http import Http404
from drf_yasg.utils import swagger_auto_schema
from rest_framework import permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView


SUPPORTED_AVATAR_EXTENSIONS = {'.gif', '.jpeg', '.jpg', '.png', '.webp'}


class AvatarDeleteSerializer(serializers.Serializer):
    path = serializers.CharField()

    def validate_path(self, value):
        normalized = str(PurePosixPath(value))
        parts = PurePosixPath(normalized).parts
        if (
            not value
            or value.startswith('/')
            or '\\' in value
            or '..' in parts
            or PurePosixPath(normalized).suffix.lower() not in SUPPORTED_AVATAR_EXTENSIONS
        ):
            raise serializers.ValidationError("Chemin d'avatar invalide.")
        return normalized


class AvatarDetailView(APIView):
    """Delete an avatar from the configured B2 bucket."""

    permission_classes = [permissions.IsAdminUser]

    @swagger_auto_schema(
        operation_summary='Supprimer un avatar',
        operation_description=(
            "Supprime l'objet du bucket B2 d'avatars. Reserve au staff."
        ),
        responses={204: 'Avatar supprime.', 404: 'Avatar introuvable.'},
    )
    def delete(self, _request, avatar_path):
        serializer = AvatarDeleteSerializer(data={'path': avatar_path})
        serializer.is_valid(raise_exception=True)
        safe_path = serializer.validated_data['path']
        storage = storages['final_avatars']
        if not storage.exists(safe_path):
            raise Http404('Avatar introuvable.')
        storage.delete(safe_path)
        return Response(status=status.HTTP_204_NO_CONTENT)
