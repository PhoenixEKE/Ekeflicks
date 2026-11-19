from math import ceil

from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class ApiPageNumberPagination(PageNumberPagination):
    """Stable, self-describing pagination contract shared by every list route."""

    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

    def get_paginated_response(self, data):
        count = self.page.paginator.count
        page_size = self.get_page_size(self.request) or self.page_size
        return Response({
            'count': count,
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'page': self.page.number,
            'page_size': page_size,
            'total_pages': ceil(count / page_size) if count else 0,
            'results': data,
        })

