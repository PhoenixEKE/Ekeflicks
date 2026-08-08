import base64
from types import SimpleNamespace
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase, override_settings
from django.urls import path, reverse
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework.views import APIView

from apps.common.avatar_detail_views import AvatarDetailView
from apps.common.avatar_views import AvatarListView
from apps.common.exceptions import api_exception_handler
from apps.common.pagination import ApiPageNumberPagination


class FakeAvatarStorage:
    directories = {
        '': (['children'], ['adult.png', 'notes.txt', 'portrait.WEBP']),
        'children': ([], ['child.jpg']),
    }

    def listdir(self, directory):
        return self.directories[directory]

    def url(self, path):
        return f'https://cdn.example.com/avatars/{path}'

    def __init__(self):
        self.saved = {}

    def exists(self, path):
        return path in self.saved

    def save(self, path, uploaded_file):
        self.saved[path] = uploaded_file.read()
        return path

    def delete(self, path):
        del self.saved[path]


class ContractView(APIView):
    authentication_classes = []
    permission_classes = []

    def get(self, request):
        raise ValidationError({'email': ['Adresse invalide.']})


urlpatterns = [path('api/v1/contract/', ContractView.as_view())]


class ApiContractTests(SimpleTestCase):
    def test_pagination_metadata_and_page_size_limit(self):
        request = Request(APIRequestFactory().get('/items/?page=2&page_size=2'))
        paginator = ApiPageNumberPagination()
        page = paginator.paginate_queryset(list(range(5)), request)
        payload = paginator.get_paginated_response(page).data
        self.assertEqual(payload['results'], [2, 3])
        self.assertEqual(payload['total_pages'], 3)
        self.assertEqual(payload['page'], 2)

    def test_validation_error_contract(self):
        request = APIRequestFactory().get('/api/v1/contract/')
        request.request_id = 'request-123'
        exc = serializers.ValidationError({'email': ['Adresse invalide.']})
        response = api_exception_handler(exc, {'request': request})
        self.assertEqual(response.data['code'], 'validation_error')
        self.assertEqual(response.data['request_id'], 'request-123')
        self.assertEqual(response.data['errors']['email'], ['Adresse invalide.'])
        self.assertEqual(response.data['email'], ['Adresse invalide.'])

    @override_settings(ROOT_URLCONF=__name__)
    def test_version_headers_and_unsupported_version(self):
        response = self.client.get('/api/v1/contract/', HTTP_X_API_VERSION='2')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()['code'], 'unsupported_api_version')
        self.assertEqual(response['X-API-Version'], '1')


class AvatarEndpointTests(SimpleTestCase):
    @patch(
        'apps.common.avatar_views.storages',
        {'final_avatars': FakeAvatarStorage()},
    )
    def test_avatar_list_is_public_and_only_returns_images(self):
        response = self.client.get(reverse('avatar-list'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'avatars': [
                    {
                        'name': 'adult',
                        'path': 'adult.png',
                        'url': 'https://cdn.example.com/avatars/adult.png',
                    },
                    {
                        'name': 'child',
                        'path': 'children/child.jpg',
                        'url': 'https://cdn.example.com/avatars/children/child.jpg',
                    },
                    {
                        'name': 'portrait',
                        'path': 'portrait.WEBP',
                        'url': 'https://cdn.example.com/avatars/portrait.WEBP',
                    },
                ],
            },
        )

    def test_staff_can_upload_and_delete_an_avatar(self):
        storage = FakeAvatarStorage()
        staff = SimpleNamespace(pk=1, is_authenticated=True, is_staff=True)
        gif = SimpleUploadedFile(
            'Mon Avatar.gif',
            base64.b64decode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='),
            content_type='image/gif',
        )
        request = APIRequestFactory().post(
            reverse('avatar-list'),
            {'name': 'Avatar Junior', 'file': gif},
            format='multipart',
        )
        force_authenticate(request, user=staff)

        with patch(
            'apps.common.avatar_views.storages',
            {'final_avatars': storage},
        ):
            response = AvatarListView.as_view()(request)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['path'], 'catalog/avatar-junior.gif')
        self.assertTrue(storage.exists('catalog/avatar-junior.gif'))

        request = APIRequestFactory().delete(
            reverse('avatar-detail', kwargs={'avatar_path': response.data['path']})
        )
        force_authenticate(request, user=staff)
        with patch(
            'apps.common.avatar_detail_views.storages',
            {'final_avatars': storage},
        ):
            response = AvatarDetailView.as_view()(
                request,
                avatar_path='catalog/avatar-junior.gif',
            )

        self.assertEqual(response.status_code, 204)
        self.assertFalse(storage.exists('catalog/avatar-junior.gif'))

    def test_avatar_writes_are_restricted_to_staff(self):
        request = APIRequestFactory().post(
            reverse('avatar-list'),
            {},
            format='multipart',
        )
        force_authenticate(
            request,
            user=SimpleNamespace(pk=2, is_authenticated=True, is_staff=False),
        )

        response = AvatarListView.as_view()(request)

        self.assertEqual(response.status_code, 403)

    def test_delete_rejects_parent_directory_paths(self):
        request = APIRequestFactory().delete('/api/v1/avatars/unsafe/')
        force_authenticate(
            request,
            user=SimpleNamespace(pk=1, is_authenticated=True, is_staff=True),
        )

        response = AvatarDetailView.as_view()(request, avatar_path='../secret.png')

        self.assertEqual(response.status_code, 400)
