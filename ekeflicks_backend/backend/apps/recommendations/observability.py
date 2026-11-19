from __future__ import annotations

import logging
import time
import uuid
from collections.abc import Callable
from functools import wraps
from typing import Any

from rest_framework.response import Response


logger = logging.getLogger("apps.recommendations.eke_ai")

REQUEST_ID_HEADER = "X-Request-ID"
SERVER_TIMING_HEADER = "Server-Timing"
RESPONSE_TIME_HEADER = "X-Response-Time-Ms"


def _request_id(request: Any) -> str:
    """
    Reuse the correlation ID established by ApiContractMiddleware.

    The middleware is the authoritative request correlation layer for the
    complete EKEFLICKS API. The fallback exists only for direct invocation
    outside the normal Django middleware chain.
    """

    request_id = str(
        getattr(request, "request_id", "") or ""
    ).strip()

    if request_id:
        return request_id

    return str(uuid.uuid4())


def observe_eke_ai(operation: str) -> Callable:
    """
    Observe one public EKE IA endpoint without changing its business contract.

    Correlation authority:
      ApiContractMiddleware -> request.request_id

    Adds EKE IA timing metadata and emits correlated completion/failure logs.
    """

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapped(
            self: Any,
            request: Any,
            *args: Any,
            **kwargs: Any,
        ) -> Any:
            request_id = _request_id(request)
            started = time.perf_counter()

            try:
                response = func(
                    self,
                    request,
                    *args,
                    **kwargs,
                )
            except Exception:
                duration_ms = (
                    time.perf_counter() - started
                ) * 1000.0

                logger.exception(
                    "eke_ai_request_failed "
                    "operation=%s "
                    "request_id=%s "
                    "duration_ms=%.2f",
                    operation,
                    request_id,
                    duration_ms,
                )
                raise

            duration_ms = (
                time.perf_counter() - started
            ) * 1000.0

            if isinstance(response, Response):
                response[REQUEST_ID_HEADER] = request_id
                response[RESPONSE_TIME_HEADER] = (
                    f"{duration_ms:.2f}"
                )
                response[SERVER_TIMING_HEADER] = (
                    f'eke_ai;dur={duration_ms:.2f};'
                    f'desc="{operation}"'
                )

                status_code = response.status_code
            else:
                status_code = getattr(
                    response,
                    "status_code",
                    "unknown",
                )

            logger.info(
                "eke_ai_request_completed "
                "operation=%s "
                "request_id=%s "
                "status=%s "
                "duration_ms=%.2f",
                operation,
                request_id,
                status_code,
                duration_ms,
            )

            return response

        return wrapped

    return decorator
