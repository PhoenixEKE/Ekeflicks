from rest_framework import status
from rest_framework.views import exception_handler as drf_exception_handler


ERROR_TITLES = {
    400: 'Requete invalide',
    401: 'Authentification requise',
    403: 'Acces refuse',
    404: 'Ressource introuvable',
    405: 'Methode non autorisee',
    409: 'Conflit',
    415: 'Format non supporte',
    429: 'Trop de requetes',
    500: 'Erreur interne',
}


def _serialize_errors(value):
    if isinstance(value, dict):
        return {key: _serialize_errors(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_serialize_errors(item) for item in value]
    return str(value)


def api_exception_handler(exc, context):
    """Render every DRF failure as an RFC 7807-inspired JSON problem."""
    response = drf_exception_handler(exc, context)
    if response is None:
        return None

    original = response.data
    raw_detail = original.get('detail') if isinstance(original, dict) else None
    code = getattr(raw_detail, 'code', None)
    detail = str(raw_detail) if raw_detail else ERROR_TITLES.get(response.status_code, 'Erreur API')
    if not code and hasattr(exc, 'get_codes'):
        codes = exc.get_codes()
        code = codes if isinstance(codes, str) else 'validation_error'

    request = context.get('request')
    request_id = getattr(request, 'request_id', None)
    response.data = {
        'type': f'https://api.ekeflicks.com/problems/{code or "api_error"}',
        'title': ERROR_TITLES.get(response.status_code, 'Erreur API'),
        'status': response.status_code,
        'code': code or 'api_error',
        'detail': detail,
        'errors': _serialize_errors(original) if response.status_code == status.HTTP_400_BAD_REQUEST else None,
        'instance': request.path if request else None,
        'request_id': request_id,
    }
    response['Content-Type'] = 'application/problem+json'
    return response
