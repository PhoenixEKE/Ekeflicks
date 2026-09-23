"""
G5-3F — EKE IA social compatibility.

This module adapts the existing G5-2 EKE IA user context to
Salon social matching.

Architecture:

    EKE IA calculates compatibility.
    PostgreSQL determines eligibility.

The module never exposes raw behavioral identifiers through the
public Salon API.

It deliberately reuses G5-2B build_user_context instead of
duplicating WatchHistory / Like / Favorite / Rating extraction.

Content recommendation candidate generation and content ranking are
not reused here because they rank Content objects, not social users.
"""

from __future__ import annotations

from dataclasses import dataclass

from apps.recommendations.user_context import (
    EkeAIUserContext,
    build_user_context,
)


EKE_SOCIAL_MATCHING_VERSION = "g5_3f_v1"


@dataclass(frozen=True)
class EkeSocialCompatibility:
    version: str
    score: int
    reasons: tuple[str, ...]
    common_content_ids: tuple[str, ...]
    common_genre_slugs: tuple[str, ...]


def build_social_context(
    *,
    user,
    profile,
):
    """
    Build the canonical EKE IA context for one social participant.

    Profile ownership and activity remain enforced by G5-2B.
    """

    return build_user_context(
        user=user,
        profile_id=profile.pk,
        current_intent="",
    )


def _content_signal_ids(context):
    """
    Internal-only behavioral content universe.

    These identifiers are used for compatibility calculation but
    must never be exposed by the public social matching serializer.
    """

    ids = set(
        context.watched_content_ids
    )

    ids.update(
        context.liked_content_ids
    )

    ids.update(
        context.favorite_content_ids
    )

    ids.update(
        item.content_id
        for item in context.ratings
    )

    return {
        str(value)
        for value in ids
    }


def _genre_weights(context):
    return {
        item.slug: max(
            0,
            int(item.weight),
        )
        for item in context.preferred_genres
        if item.slug
    }


def _positive_rating_ids(context):
    """
    A rating >= 3.5 is considered a positive affinity signal.

    This threshold is internal to G5-3F compatibility and does not
    alter the persisted Rating model.
    """

    return {
        str(item.content_id)
        for item in context.ratings
        if float(item.rating) >= 3.5
    }


def _engagement_ids(context):
    """
    Explicit positive engagement is stronger than passive viewing.
    """

    return {
        str(value)
        for value in (
            set(context.liked_content_ids)
            | set(context.favorite_content_ids)
        )
    }


def _behavior_confidence(context):
    counts = context.signal_counts or {}

    watch = min(
        int(counts.get("watch_history", 0) or 0),
        20,
    )

    likes = min(
        int(counts.get("likes", 0) or 0),
        20,
    )

    favorites = min(
        int(counts.get("favorites", 0) or 0),
        20,
    )

    ratings = min(
        int(counts.get("ratings", 0) or 0),
        20,
    )

    raw = (
        watch * 0.20
        + likes * 0.30
        + favorites * 0.40
        + ratings * 0.30
    )

    return min(
        raw,
        10.0,
    )


def _shared_genre_affinity(
    requester_context,
    candidate_context,
):
    requester = _genre_weights(
        requester_context
    )

    candidate = _genre_weights(
        candidate_context
    )

    common = tuple(
        sorted(
            set(requester)
            & set(candidate)
        )
    )

    if not common:
        return (
            0.0,
            common,
        )

    overlap = sum(
        min(
            requester[slug],
            candidate[slug],
        )
        for slug in common
    )

    return (
        min(
            float(overlap) * 5.0,
            25.0,
        ),
        common,
    )


def calculate_social_compatibility(
    *,
    requester_context,
    candidate_context,
):
    """
    Calculate deterministic social compatibility from two canonical
    EKE IA contexts.

    Maximum score: 100

    Components:
    - shared behavioral content affinity: 35
    - weighted genre affinity: 25
    - shared explicit engagement: 15
    - shared positive ratings: 10
    - behavioral confidence: 10
    - community/discovery fallback: 5

    The final reasons are explainable but contain no private values.
    """

    if not isinstance(
        requester_context,
        EkeAIUserContext,
    ):
        raise TypeError(
            "requester_context must be an EkeAIUserContext."
        )

    if not isinstance(
        candidate_context,
        EkeAIUserContext,
    ):
        raise TypeError(
            "candidate_context must be an EkeAIUserContext."
        )

    score = 0.0
    reasons = []

    requester_contents = _content_signal_ids(
        requester_context
    )

    candidate_contents = _content_signal_ids(
        candidate_context
    )

    common_contents = tuple(
        sorted(
            requester_contents
            & candidate_contents
        )
    )

    if common_contents:
        score += min(
            len(common_contents) * 7.0,
            35.0,
        )

        reasons.append(
            "shared_content_taste"
        )

    genre_score, common_genres = (
        _shared_genre_affinity(
            requester_context,
            candidate_context,
        )
    )

    if genre_score > 0:
        score += genre_score

        reasons.append(
            "shared_genres"
        )

    common_engagement = (
        _engagement_ids(
            requester_context
        )
        & _engagement_ids(
            candidate_context
        )
    )

    if common_engagement:
        score += min(
            len(common_engagement) * 7.5,
            15.0,
        )

        reasons.append(
            "shared_engagement"
        )

    common_positive_ratings = (
        _positive_rating_ids(
            requester_context
        )
        & _positive_rating_ids(
            candidate_context
        )
    )

    if common_positive_ratings:
        score += min(
            len(common_positive_ratings) * 5.0,
            10.0,
        )

        reasons.append(
            "shared_positive_ratings"
        )

    requester_confidence = (
        _behavior_confidence(
            requester_context
        )
    )

    candidate_confidence = (
        _behavior_confidence(
            candidate_context
        )
    )

    confidence = min(
        requester_confidence,
        candidate_confidence,
    )

    if confidence > 0:
        score += confidence

        reasons.append(
            "behavior_confidence"
        )

    if not reasons:
        score += 5.0

        reasons.append(
            "community_discovery"
        )

    return EkeSocialCompatibility(
        version=EKE_SOCIAL_MATCHING_VERSION,
        score=min(
            100,
            max(
                0,
                int(round(score)),
            ),
        ),
        reasons=tuple(
            dict.fromkeys(reasons)
        ),
        common_content_ids=common_contents,
        common_genre_slugs=common_genres,
    )
