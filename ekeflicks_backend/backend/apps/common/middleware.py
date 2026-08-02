import uuid

from django.http import JsonResponse


class ApiContractMiddleware:
    """Expose request correlation and the negotiated API contract version."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.request_id = request.headers.get('X-Request-ID') or str(uuid.uuid4())
        requested_version = request.headers.get('X-API-Version')
        if request.path.startswith('/api/') and requested_version not in (None, '1'):
            response = JsonResponse({
                'type': 'https://api.ekeflicks.com/problems/unsupported_api_version',
                'title': 'Version API non supportee',
                'status': 400,
                'code': 'unsupported_api_version',
                'detail': "Utilisez l'API v1 via /api/v1/ et X-API-Version: 1.",
                'errors': None,
                'instance': request.path,
                'request_id': request.request_id,
            }, status=400, content_type='application/problem+json')
        else:
            response = self.get_response(request)
        response['X-Request-ID'] = request.request_id
        response['X-API-Version'] = '1'
        response['API-Supported-Versions'] = '1'
        return response

