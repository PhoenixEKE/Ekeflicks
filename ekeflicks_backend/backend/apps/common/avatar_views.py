from pathlib import PurePosixPath
from uuid import uuid4

from django.core.files.storage import storages
from django.utils.text import slugify
from drf_yasg.utils import swagger_auto_schema
from rest_framework import serializers, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.permissions import IsAdminOrReadOnly


SUPPORTED_AVATAR_EXTENSIONS = {'.gif', '.jpeg', '.jpg', '.png', '.webp'}


class AvatarSerializer(serializers.Serializer):
    name = serializers.CharField()
    path = serializers.CharField()
    url = serializers.URLField()


class AvatarListSerializer(serializers.Serializer):
    avatars = AvatarSerializer(many=True)


class AvatarUploadSerializer(serializers.Serializer):
    file = serializers.ImageField(required=True)
    name = serializers.CharField(required=False, allow_blank=True, max_length=100)

    def validate_file(self, uploaded_file):
        extension = PurePosixPath(uploaded_file.name).suffix.lower()
        if extension not in SUPPORTED_AVATAR_EXTENSIONS:
            raise serializers.ValidationError(
                'Formats acceptes: GIF, JPEG, PNG et WebP.'
            )
        return uploaded_file

    def storage_path(self):
        uploaded_file = self.validated_data['file']
        requested_name = self.validated_data.get('name') or PurePosixPath(
            uploaded_file.name
        ).stem
        safe_name = slugify(requested_name) or f'avatar-{uuid4().hex}'
        extension = PurePosixPath(uploaded_file.name).suffix.lower()
        return f"{safe_name}{extension}"

def iter_avatar_paths(storage, directory=''):
    """Iterate over image objects in the B2 avatar bucket."""
    directories, files = storage.listdir(directory)

    for filename in files:
        path = str(PurePosixPath(directory, filename))
        if PurePosixPath(filename).suffix.lower() in SUPPORTED_AVATAR_EXTENSIONS:
            yield path

    for child in directories:
        child_directory = str(PurePosixPath(directory, child))
        yield from iter_avatar_paths(storage, child_directory)


class AvatarListView(APIView):
    """List publicly and let staff add avatars to the configured B2 bucket."""

    permission_classes = [IsAdminOrReadOnly]
    parser_classes = [MultiPartParser, FormParser]

    @swagger_auto_schema(
        operation_summary='Lister les avatars disponibles',
        operation_description=(
            "Retourne publiquement les avatars disponibles afin qu'un utilisateur "
            "puisse en choisir un avant son inscription."
        ),
        responses={200: AvatarListSerializer},
        security=[],
    )
    def get(self, _request):
        storage = storages['final_avatars']
        avatars = [
            {
                'name': PurePosixPath(path).stem,
                'path': path,
                'url': storage.url(path),
            }
            for path in sorted(iter_avatar_paths(storage))
        ]
        return Response({'avatars': avatars})

    @swagger_auto_schema(
        operation_summary='Ajouter un avatar',
        operation_description=(
            "Ajoute un avatar dans le bucket B2 configure. Reserve au staff."
        ),
        request_body=AvatarUploadSerializer,
        responses={201: AvatarSerializer},
    )
    def post(self, request):
        serializer = AvatarUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        storage = storages['final_avatars']
        avatar_path = serializer.storage_path()
        if storage.exists(avatar_path):
            return Response(
                {'detail': 'Un avatar avec ce nom existe deja.'},
                status=status.HTTP_409_CONFLICT,
            )

        saved_path = storage.save(avatar_path, serializer.validated_data['file'])
        payload = {
            'name': PurePosixPath(saved_path).stem,
            'path': saved_path,
            'url': storage.url(saved_path),
        }
        return Response(payload, status=status.HTTP_201_CREATED)
