from pathlib import PurePosixPath

from django.core.files.storage import storages
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView


SUPPORTED_AVATAR_EXTENSIONS = {'.gif', '.jpeg', '.jpg', '.png', '.webp'}


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
    """List the avatars stored in the configured B2 avatar bucket."""

    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get(self, _request):
        storage = storages['final_avatars']
        avatars = [
            {
                'name': PurePosixPath(path).stem,
                'url': storage.url(path),
            }
            for path in sorted(iter_avatar_paths(storage))
        ]
        return Response({'avatars': avatars})
