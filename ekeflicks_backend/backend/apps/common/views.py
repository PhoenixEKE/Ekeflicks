from pathlib import PurePosixPath

from django.core.files.storage import storages
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView


AVATAR_EXTENSIONS = {'.gif', '.jpeg', '.jpg', '.png', '.webp'}


def _avatar_files(storage, directory=''):
    """Yield image files from an avatar storage, including nested folders."""
    directories, files = storage.listdir(directory)
    for filename in files:
        path = str(PurePosixPath(directory, filename))
        if PurePosixPath(filename).suffix.lower() in AVATAR_EXTENSIONS:
            yield path
    for child_directory in directories:
        child_path = str(PurePosixPath(directory, child_directory))
        yield from _avatar_files(storage, child_path)


class AvatarListView(APIView):
    """Return the selectable avatars published in the avatar media storage."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, _request):
        storage = storages['final_avatars']
        avatars = [
            {
                'name': PurePosixPath(path).stem,
                'url': storage.url(path),
            }
            for path in sorted(_avatar_files(storage))
        ]
        return Response({'avatars': avatars})
