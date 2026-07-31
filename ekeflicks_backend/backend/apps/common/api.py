from rest_framework.response import Response


TRUE_VALUES = {'1', 'true', 'yes', 'on'}


def is_true(value):
    return str(value).lower() in TRUE_VALUES


def is_int(value):
    try:
        int(value)
        return True
    except (TypeError, ValueError):
        return False


def paginate(viewset, queryset, serializer_class=None):
    page = viewset.paginate_queryset(queryset)
    serializer_class = serializer_class or viewset.get_serializer_class()
    if page is not None:
        serializer = serializer_class(page, many=True, context=viewset.get_serializer_context())
        return viewset.get_paginated_response(serializer.data)

    serializer = serializer_class(queryset, many=True, context=viewset.get_serializer_context())
    return Response(serializer.data)
