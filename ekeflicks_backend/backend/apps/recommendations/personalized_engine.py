"""
G5-2D — EKE IA personalized recommendation engine.

This layer transforms:
    user context + PostgreSQL-authorized candidate pool
into:
    deterministic personalized recommendations.

G5-2D establishes the recommendation engine contract.

It intentionally does NOT implement the advanced ranking model planned
for G5-2E.

Rules:
- candidates must originate from G5-2C;
- PostgreSQL authorization has already happened before this layer;
- watched contents remain excluded;
- preferred genres are personal signals;
- global Top 10 is only a supporting signal;
- trending/popularity are fallback discovery signals;
- no fabricated content;
- no persistence;
- no LLM.
"""

from dataclasses import asdict, dataclass, field

from apps.recommendations.candidate_generation import (
    CandidatePool,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)
from apps.recommendations.ranking import (
    rank_candidates,
)
from apps.recommendations.diversification import (
    diversify_ranked_candidates,
)


EKE_AI_PERSONALIZED_ENGINE_VERSION = "g5_2d_v1"


class PersonalizedRecommendationError(ValueError):
    """Invalid personalized recommendation request."""


@dataclass(frozen=True)
class PersonalizedRecommendation:
    content_id: str
    score: float
    reasons: tuple = field(default_factory=tuple)
    sources: tuple = field(default_factory=tuple)

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class PersonalizedRecommendationResult:
    version: str
    profile_id: str
    recommendations: tuple
    cold_start: bool

    def to_dict(self):
        return {
            "version": self.version,
            "profile_id": self.profile_id,
            "recommendation_count": len(
                self.recommendations
            ),
            "cold_start": self.cold_start,
            "recommendations": [
                item.to_dict()
                for item in self.recommendations
            ],
        }


def _normalize_limit(limit):
    try:
        value = int(limit)
    except (TypeError, ValueError) as exc:
        raise PersonalizedRecommendationError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > 100:
        raise PersonalizedRecommendationError(
            "limit must be between 1 and 100."
        )

    return value


def _genre_weights(context):
    return {
        item.slug: int(item.weight)
        for item in context.preferred_genres
    }


def _is_cold_start(context):
    counts = context.signal_counts

    return not any(
        int(counts.get(key, 0) or 0) > 0
        for key in (
            "watch_history",
            "likes",
            "favorites",
            "ratings",
        )
    )


def _score_candidate(
    *,
    candidate,
    genre_weights,
    cold_start,
):
    """
    G5-2D baseline personalization.

    This score only establishes deterministic recommendation behavior.
    G5-2E will own the advanced scoring/ranking formula.
    """

    score = 0.0
    reasons = []

    matched_genres = tuple(
        slug
        for slug in candidate.genre_matches
        if slug in genre_weights
    )

    if matched_genres:
        genre_signal = sum(
            genre_weights[slug]
            for slug in matched_genres
        )

        score += min(
            float(genre_signal) * 10.0,
            50.0,
        )

        reasons.append(
            "preferred_genre"
        )

    if "top10" in candidate.sources:
        position = (
            candidate.top10_position
            if candidate.top10_position
            is not None
            else 10
        )

        score += max(
            0.0,
            11.0 - float(position),
        )

        reasons.append(
            "global_top10"
        )

    if "trending" in candidate.sources:
        score += min(
            max(
                float(
                    candidate.trending_score
                ),
                0.0,
            ),
            100.0,
        ) * 0.10

        reasons.append(
            "trending"
        )

    if "popular" in candidate.sources:
        score += min(
            max(
                float(
                    candidate.popularity_score
                ),
                0.0,
            ),
            100.0,
        ) * 0.05

        reasons.append(
            "popular"
        )

    if cold_start:
        # Cold start uses global discovery signals only.
        # It must not invent personal affinity.
        reasons = [
            reason
            for reason in reasons
            if reason != "preferred_genre"
        ]

    return (
        round(score, 6),
        tuple(sorted(set(reasons))),
    )


def _personalized_reasons(ranked_item):
    """
    Preserve the G5-2D public explanation contract while G5-2E
    keeps its richer internal ranking vocabulary.

    Ranking internals:
        preference / behavior_confidence / current_intent /
        quality / trend / discovery

    Personalized public reasons:
        preferred_genre / global_top10 / trending / popular /
        behavior_confidence / current_intent / quality / discovery
    """

    reasons = []

    internal = set(
        ranked_item.reasons
    )

    sources = set(
        ranked_item.sources
    )

    if "preference" in internal:
        reasons.append(
            "preferred_genre"
        )

    if "behavior_confidence" in internal:
        reasons.append(
            "behavior_confidence"
        )

    if "current_intent" in internal:
        reasons.append(
            "current_intent"
        )

    if "quality" in internal:
        reasons.append(
            "quality"
        )

    if (
        "top10" in sources
        and "trend" in internal
    ):
        reasons.append(
            "global_top10"
        )

    if (
        "trending" in sources
        and "trend" in internal
    ):
        reasons.append(
            "trending"
        )

    if "popular" in sources:
        reasons.append(
            "popular"
        )

    if "discovery" in internal:
        reasons.append(
            "discovery"
        )

    return tuple(
        dict.fromkeys(
            reasons
        )
    )


def recommend_for_context(
    *,
    context,
    candidate_pool,
    limit=20,
):
    """
    Produce deterministic personalized recommendations.

    The function only consumes a candidate pool that has already passed
    G5-2C PostgreSQL eligibility.
    """

    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise PersonalizedRecommendationError(
            "context must be an EkeAIUserContext."
        )

    if not isinstance(
        candidate_pool,
        CandidatePool,
    ):
        raise PersonalizedRecommendationError(
            "candidate_pool must be a CandidatePool."
        )

    if (
        candidate_pool.profile_id
        != context.profile_id
    ):
        raise PersonalizedRecommendationError(
            "context and candidate pool profile mismatch."
        )

    limit = _normalize_limit(limit)

    cold_start = _is_cold_start(
        context
    )

    watched_ids = set(
        context.watched_content_ids
    )

    safe_candidates = tuple(
        candidate
        for candidate
        in candidate_pool.candidates
        if candidate.content_id
        not in watched_ids
    )

    ranking_limit = min(
        max(
            limit * 3,
            limit,
        ),
        100,
    )

    ranked = rank_candidates(
        context=context,
        candidates=safe_candidates,
        limit=ranking_limit,
    )

    diversified = diversify_ranked_candidates(
        context=context,
        ranked_candidates=ranked,
        candidates=safe_candidates,
        limit=limit,
    )

    recommendations = tuple(
        PersonalizedRecommendation(
            content_id=item.content_id,
            score=item.score,
            reasons=_personalized_reasons(
                item
            ),
            sources=item.sources,
        )
        for item in diversified
    )

    return PersonalizedRecommendationResult(
        version=EKE_AI_PERSONALIZED_ENGINE_VERSION,
        profile_id=context.profile_id,
        recommendations=recommendations,
        cold_start=cold_start,
    )
