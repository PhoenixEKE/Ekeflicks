from rest_framework import status
from rest_framework.views import exception_handler as drf_exception_handler


ERROR_TITLES = {
    400: 'Requête invalide',
    401: 'Authentification requise',
    403: 'Accès refusé',
    404: 'Ressource introuvable',
    405: 'Méthode non autorisée',
    409: 'Conflit',
    415: 'Format non supporté',
    429: 'Trop de requêtes',
    500: 'Erreur interne',
}


def _serialize_errors(value):
    if isinstance(value, dict):
        return {
            key: _serialize_errors(item)
            for key, item in value.items()
        }

    if isinstance(value, (list, tuple)):
        return [_serialize_errors(item) for item in value]

    return str(value)


def _first_error_message(value):
    """
    Extrait le premier message métier réellement utile d'une erreur DRF.

    Exemples :
        {'email': ['Cette adresse email est déjà utilisée.']}
            -> Cette adresse email est déjà utilisée.

        {'non_field_errors': ['Données invalides.']}
            -> Données invalides.

        {'detail': 'Authentification requise.'}
            -> Authentification requise.
    """
    if value is None:
        return None

    if isinstance(value, dict):
        # Priorités sémantiques habituelles DRF.
        for key in ('detail', 'non_field_errors'):
            if key in value:
                message = _first_error_message(value[key])
                if message:
                    return message

        # Puis première erreur de champ disponible.
        for item in value.values():
            message = _first_error_message(item)
            if message:
                return message

        return None

    if isinstance(value, (list, tuple)):
        for item in value:
            message = _first_error_message(item)
            if message:
                return message

        return None

    text = str(value).strip()
    return text or None


def api_exception_handler(exc, context):
    """Render every DRF failure as an RFC 7807-inspired JSON problem."""
    response = drf_exception_handler(exc, context)

    if response is None:
        return None

    original = response.data

    raw_detail = (
        original.get('detail')
        if isinstance(original, dict)
        else None
    )

    code = getattr(raw_detail, 'code', None)

    if not code and hasattr(exc, 'get_codes'):
        codes = exc.get_codes()
        code = (
            codes
            if isinstance(codes, str)
            else 'validation_error'
        )

    # Pour les erreurs de validation, ne jamais masquer le message métier
    # par le générique "Requête invalide".
    detail = (
        _first_error_message(original)
        or ERROR_TITLES.get(
            response.status_code,
            'Erreur API',
        )
    )

    request = context.get('request')
    request_id = getattr(
        request,
        'request_id',
        None,
    )

    serialized_errors = (
        _serialize_errors(original)
        if response.status_code == status.HTTP_400_BAD_REQUEST
        else None
    )

    response.data = {
        'type': (
            'https://api.ekeflicks.com/problems/'
            f'{code or "api_error"}'
        ),
        'title': ERROR_TITLES.get(
            response.status_code,
            'Erreur API',
        ),
        'status': response.status_code,
        'code': code or 'api_error',
        'detail': detail,
        'errors': serialized_errors,
        'instance': request.path if request else None,
        'request_id': request_id,
    }

    # Compatibilité avec les anciens clients mobiles :
    # conserver également les erreurs de champs au premier niveau.
    if isinstance(serialized_errors, dict):
        for field, messages in serialized_errors.items():
            response.data.setdefault(
                field,
                messages,
            )

    response['Content-Type'] = 'application/problem+json'

    return response
