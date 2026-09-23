"""
G5-2A — EKE IA foundation.

Architecture rule:

    EKE IA understands and recommends.
    PostgreSQL authorizes.
    ClickHouse measures.
    EKEFLICKS APIs execute.

This module deliberately does NOT implement the final recommendation
algorithm. It establishes the hard eligibility boundary and exposes
the architecture contract used by the following G5-2 phases.
"""

from django.conf import settings
from django.db.models import Q
from django.utils import timezone

from core.models import Content


EKE_AI_FOUNDATION_VERSION = "g5_2a_v1"

EKE_AI_POLICY = {
    "ai_role": "understand_and_recommend",
    "authorization_source": "postgresql",
    "analytics_source": "clickhouse",
    "graph_source": "neo4j_optional",
    "execution_source": "ekeflicks_api",
}

EKE_AI_SIGNAL_SOURCES = {
    "catalog": "postgresql",
    "availability": "postgresql",
    "rights": "postgresql",
    "profiles": "postgresql",
    "likes": "postgresql",
    "favorites": "postgresql",
    "ratings": "postgresql",
    "watch_history": "postgresql",
    "behavioral_analytics": "clickhouse",
    "global_top10": "postgresql_snapshot",
    "content_graph": "neo4j_optional",
}

EKE_AI_HARD_RULES = {
    "postgresql_eligibility_before_ranking": True,
    "favorite_is_like": False,
    "top10_is_personal_recommendation": False,
    "allow_fabricated_content": False,
    "allow_ai_to_bypass_rights": False,
}


def eligible_content_queryset(*, at=None):
    """
    Return the PostgreSQL-authorized candidate catalogue.

    This is a hard security/product boundary. Recommendation engines,
    graph engines and later AI ranking stages must only operate on IDs
    returned by this queryset.

    Current product eligibility follows the already-established
    Top 10 rule:
    - producer submission approved;
    - available_from reached, when defined;
    - available_until not expired, when defined.

    Content.status is intentionally not activated as an eligibility
    gate here because that field is not yet authoritative for this
    product rule.
    """

    current_date = (
        at.date()
        if hasattr(at, "date")
        else at
    )

    if current_date is None:
        current_date = timezone.localdate()

    return (
        Content.objects
        .filter(
            producer_submission_status="approved",
        )
        .filter(
            Q(available_from__isnull=True)
            | Q(available_from__lte=current_date),
        )
        .filter(
            Q(available_until__isnull=True)
            | Q(available_until__gte=current_date),
        )
    )


def eligible_content_ids(*, at=None):
    """
    Return only PostgreSQL-authorized content IDs.

    Keeping this helper explicit prevents future engines from building
    an unrestricted candidate set and filtering too late.
    """

    return list(
        eligible_content_queryset(
            at=at,
        ).values_list(
            "id",
            flat=True,
        )
    )


def eke_ai_foundation_status():
    """
    Return non-secret runtime information about the EKE IA foundation.
    """

    from apps.recommendations.engine import (
        neo4j_enabled,
        neo4j_package_available,
    )

    configured_engine = getattr(
        settings,
        "RECOMMENDATION_ENGINE",
        "django",
    )

    return {
        "service": "eke_ai",
        "foundation_version":
            EKE_AI_FOUNDATION_VERSION,
        "phase": "foundation",
        "configured_recommendation_engine":
            configured_engine,
        "neo4j_package_available":
            neo4j_package_available(),
        "neo4j_enabled":
            neo4j_enabled(),
        "policy":
            dict(EKE_AI_POLICY),
        "signal_sources":
            dict(EKE_AI_SIGNAL_SOURCES),
        "hard_rules":
            dict(EKE_AI_HARD_RULES),
        "eligible_content_count":
            eligible_content_queryset().count(),
        "capabilities": {
            "foundation": True,
            "user_context": False,
            "candidate_generation": False,
            "personalized_ranking": False,
            "diversification": False,
            "semantic_search": False,
            "conversation": False,
            "feedback_learning": False,
        },
    }
