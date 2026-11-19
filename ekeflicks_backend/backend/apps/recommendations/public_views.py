"""
G5-2K — Stable public EKE IA client API.

This module is the client-facing orchestration surface for Web/Mobile/TV.

Public routes:
    GET  /api/v1/eke-ai/status/
    GET  /api/v1/eke-ai/for-you/
    POST /api/v1/eke-ai/search/
    POST /api/v1/eke-ai/chat/
    POST /api/v1/eke-ai/explain/
    POST /api/v1/eke-ai/feedback/

The existing /recommendations/* routes remain available for backwards
compatibility and internal regression coverage.

Rules:
- no recommendation/search/conversation logic is duplicated here;
- PostgreSQL remains the catalogue/eligibility authority;
- all personalized routes require authentication;
- public responses use a stable EKE IA contract;
- clients do not need to know internal recommendation modules.
"""

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.recommendations.candidate_generation import (
    EKE_AI_CANDIDATE_VERSION,
    generate_candidate_pool,
)
from apps.recommendations.conversational_assistant import (
    EKE_AI_CONVERSATIONAL_VERSION,
    ConversationalAssistantError,
    converse,
)
from apps.recommendations.diversification import (
    EKE_AI_DIVERSIFICATION_VERSION,
)
from apps.recommendations.eke_ai import (
    EKE_AI_FOUNDATION_VERSION,
    eligible_content_queryset,
)
from apps.recommendations.feedback_learning import (
    EKE_AI_FEEDBACK_VERSION,
    FeedbackLearningError,
    record_feedback,
)
from apps.recommendations.intelligent_search import (
    EKE_AI_SEARCH_VERSION,
    IntelligentSearchError,
    intelligent_search,
)
from apps.recommendations.personalized_engine import (
    EKE_AI_PERSONALIZED_ENGINE_VERSION,
    recommend_for_context,
)
from apps.recommendations.ranking import (
    EKE_AI_RANKING_VERSION,
)
from apps.recommendations.recommendation_explanations import (
    EKE_AI_EXPLANATION_VERSION,
    RecommendationExplanationError,
    explain_personalized_recommendation,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIContextError,
    build_user_context,
)


from apps.recommendations.observability import observe_eke_ai

EKE_AI_PUBLIC_API_VERSION = "g5_2k_v1"


class EkeAIPublicAPIError(ValueError):
    """Invalid public EKE IA request."""


def _normalize_limit(
    value,
    *,
    default=20,
    maximum=50,
):
    if value in (
        None,
        "",
    ):
        value = default

    try:
        value = int(
            value
        )
    except (
        TypeError,
        ValueError,
    ) as exc:
        raise EkeAIPublicAPIError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > maximum:
        raise EkeAIPublicAPIError(
            f"limit must be between 1 and {maximum}."
        )

    return value


def _serialize_personalized_result(
    result,
):
    recommendations = tuple(
        result.recommendations
    )

    ids = [
        item.content_id
        for item
        in recommendations
    ]

    authorized = {
        str(content.id): content
        for content
        in (
            eligible_content_queryset()
            .filter(
                id__in=ids
            )
        )
    }

    payload = []

    for item in recommendations:
        content = authorized.get(
            str(
                item.content_id
            )
        )

        if content is None:
            continue

        payload.append(
            {
                "content_id": str(
                    content.id
                ),
                "title": str(
                    content.title
                ),
                "score": float(
                    item.score
                ),
                "reasons": list(
                    item.reasons
                ),
            }
        )

    return payload


class EkeAIViewSet(
    viewsets.GenericViewSet
):
    """
    Stable public EKE IA API.

    Client applications should integrate this surface instead of
    coupling themselves directly to recommendation implementation routes.
    """

    permission_classes = [
        IsAuthenticated,
    ]

    @action(
        detail=False,
        methods=["get"],
        url_path="status",
        url_name="status",
    )
    @observe_eke_ai("status")
    def public_status(
        self,
        request,
    ):
        return Response(
            {
                "version": EKE_AI_PUBLIC_API_VERSION,
                "status": "ready",
                "capabilities": {
                    "for_you": True,
                    "search": True,
                    "chat": True,
                    "explain": True,
                    "feedback": True,
                },
                "components": {
                    "foundation": EKE_AI_FOUNDATION_VERSION,
                    "user_context": EKE_AI_USER_CONTEXT_VERSION,
                    "candidate_generation": EKE_AI_CANDIDATE_VERSION,
                    "personalized_engine": (
                        EKE_AI_PERSONALIZED_ENGINE_VERSION
                    ),
                    "ranking": EKE_AI_RANKING_VERSION,
                    "diversification": (
                        EKE_AI_DIVERSIFICATION_VERSION
                    ),
                    "search": EKE_AI_SEARCH_VERSION,
                    "conversation": (
                        EKE_AI_CONVERSATIONAL_VERSION
                    ),
                    "explanations": (
                        EKE_AI_EXPLANATION_VERSION
                    ),
                    "feedback": EKE_AI_FEEDBACK_VERSION,
                },
            }
        )

    @action(
        detail=False,
        methods=["get"],
        url_path="for-you",
        url_name="for-you",
    )
    @observe_eke_ai("for-you")
    def for_you(
        self,
        request,
    ):
        profile_id = (
            request.query_params.get(
                "profile_id"
            )
        )

        current_intent = (
            request.query_params.get(
                "current_intent",
                "",
            )
        )

        try:
            limit = _normalize_limit(
                request.query_params.get(
                    "limit",
                    20,
                ),
            )

            context = build_user_context(
                user=request.user,
                profile_id=profile_id,
                current_intent=current_intent,
            )

            candidate_limit = min(
                max(
                    limit * 5,
                    20,
                ),
                100,
            )

            candidate_pool = (
                generate_candidate_pool(
                    context=context,
                    limit=candidate_limit,
                )
            )

            result = recommend_for_context(
                context=context,
                candidate_pool=candidate_pool,
                limit=limit,
            )

            recommendations = (
                _serialize_personalized_result(
                    result
                )
            )

        except (
            EkeAIPublicAPIError,
            EkeAIContextError,
        ) as exc:
            return Response(
                {
                    "detail": str(
                        exc
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "version": EKE_AI_PUBLIC_API_VERSION,
                "profile_id": str(
                    context.profile_id
                ),
                "count": len(
                    recommendations
                ),
                "recommendations": recommendations,
            }
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="search",
        url_name="search",
    )
    @observe_eke_ai("search")
    def public_search(
        self,
        request,
    ):
        query = request.data.get(
            "query",
            "",
        )

        profile_id = request.data.get(
            "profile_id"
        )

        try:
            limit = _normalize_limit(
                request.data.get(
                    "limit",
                    20,
                ),
            )

            context = build_user_context(
                user=request.user,
                profile_id=profile_id,
                current_intent=query,
            )

            result = intelligent_search(
                query=query,
                context=context,
                limit=limit,
            )

        except (
            EkeAIPublicAPIError,
            IntelligentSearchError,
            EkeAIContextError,
        ) as exc:
            return Response(
                {
                    "detail": str(
                        exc
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        payload = result.to_dict()

        payload["api_version"] = (
            EKE_AI_PUBLIC_API_VERSION
        )

        return Response(
            payload
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="chat",
        url_name="chat",
    )
    @observe_eke_ai("chat")
    def public_chat(
        self,
        request,
    ):
        message = request.data.get(
            "message",
            "",
        )

        profile_id = request.data.get(
            "profile_id"
        )

        try:
            limit = _normalize_limit(
                request.data.get(
                    "limit",
                    10,
                ),
                default=10,
                maximum=20,
            )

            context = build_user_context(
                user=request.user,
                profile_id=profile_id,
                current_intent=message,
            )

            result = converse(
                message=message,
                context=context,
                limit=limit,
            )

        except (
            EkeAIPublicAPIError,
            ConversationalAssistantError,
            EkeAIContextError,
        ) as exc:
            return Response(
                {
                    "detail": str(
                        exc
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        payload = result.to_dict()

        payload["api_version"] = (
            EKE_AI_PUBLIC_API_VERSION
        )

        return Response(
            payload
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="explain",
        url_name="explain",
    )
    @observe_eke_ai("explain")
    def public_explain(
        self,
        request,
    ):
        content_id = request.data.get(
            "content_id"
        )

        profile_id = request.data.get(
            "profile_id"
        )

        current_intent = request.data.get(
            "current_intent",
            "",
        )

        try:
            context = build_user_context(
                user=request.user,
                profile_id=profile_id,
                current_intent=current_intent,
            )

            result = (
                explain_personalized_recommendation(
                    context=context,
                    content_id=content_id,
                )
            )

        except (
            RecommendationExplanationError,
            EkeAIContextError,
        ) as exc:
            return Response(
                {
                    "detail": str(
                        exc
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        payload = result.to_dict()

        payload["api_version"] = (
            EKE_AI_PUBLIC_API_VERSION
        )

        return Response(
            payload
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="feedback",
        url_name="feedback",
    )
    @observe_eke_ai("feedback")
    def public_feedback(
        self,
        request,
    ):
        try:
            result = record_feedback(
                user=request.user,
                profile_id=request.data.get(
                    "profile_id"
                ),
                content_id=request.data.get(
                    "content_id"
                ),
                action=request.data.get(
                    "action"
                ),
                rating=request.data.get(
                    "rating"
                ),
            )

        except (
            FeedbackLearningError,
            EkeAIContextError,
        ) as exc:
            return Response(
                {
                    "detail": str(
                        exc
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        payload = result.to_dict()

        payload["api_version"] = (
            EKE_AI_PUBLIC_API_VERSION
        )

        return Response(
            payload
        )
