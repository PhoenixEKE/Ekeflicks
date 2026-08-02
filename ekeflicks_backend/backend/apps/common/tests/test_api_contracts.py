from django.test import SimpleTestCase, override_settings
from django.urls import path
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory
from rest_framework.views import APIView

from apps.common.exceptions import api_exception_handler
from apps.common.pagination import ApiPageNumberPagination


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

    @override_settings(ROOT_URLCONF=__name__)
    def test_version_headers_and_unsupported_version(self):
        response = self.client.get('/api/v1/contract/', HTTP_X_API_VERSION='2')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()['code'], 'unsupported_api_version')
        self.assertEqual(response['X-API-Version'], '1')
