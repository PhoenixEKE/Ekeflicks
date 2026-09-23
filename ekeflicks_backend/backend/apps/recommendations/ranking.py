"""
G5-2E — EKE IA intelligent ranking / scoring.

Conceptual model:

    P + B + I + Q + T + D

P = personal preference affinity
B = behavioral confidence
I = current intent affinity
Q = quality signal
T = trend/global discovery signal
D = discovery bonus

This module scores already-authorized candidates.

It NEVER decides catalogue eligibility.
PostgreSQL authorization remains upstream in G5-2A/G5-2C.

The model is deliberately explicit, deterministic and explainable.
No LLM is required to rank content.
"""

from dataclasses import dataclass

from apps.recommendations.candidate_generation import (
    Candidate,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)


EKE_AI_RANKING_VERSION = "g5_2e_v1"


class RankingError(ValueError):
    """Invalid EKE IA ranking input."""


@dataclass(frozen=True)
class RankingComponents:
    preference: float = 0.0
    behavior: float = 0.0
    intent: float = 0.0
    quality: float = 0.0
    trend: float = 0.0
    discovery: float = 0.0

    @property
    def total(self):
        return round(
            self.preference
            + self.behavior
            + self.intent
            + self.quality
            + self.trend
            + self.discovery,
            6,
        )

    def to_dict(self):
        return {
            "preference": self.preference,
            "behavior": self.behavior,
            "intent": self.intent,
            "quality": self.quality,
            "trend": self.trend,
            "discovery": self.discovery,
            "total": self.total,
        }


@dataclass(frozen=True)
class RankedCandidate:
    content_id: str
    score: float
    components: RankingComponents
    reasons: tuple
    sources: tuple

    def to_dict(self):
        return {
            "content_id": self.content_id,
            "score": self.score,
            "components": self.components.to_dict(),
            "reasons": list(self.reasons),
            "sources": list(self.sources),
        }


def _clamp(value, minimum=0.0, maximum=100.0):
    return max(
        minimum,
        min(maximum, float(value or 0)),
    )


def _preferred_genre_weights(context):
    return {
        item.slug: max(
            0,
            int(item.weight),
        )
        for item in context.preferred_genres
    }


def _preference_component(
    context,
    candidate,
):
    weights = _preferred_genre_weights(
        context
    )

    matched = [
        weights[slug]
        for slug in candidate.genre_matches
        if slug in weights
    ]

    if not matched:
        return 0.0

    return round(
        min(
            sum(matched) * 6.0,
            36.0,
        ),
        6,
    )


def _behavior_component(context):
    counts = context.signal_counts or {}

    watch = min(
        int(
            counts.get(
                "watch_history",
                0,
            ) or 0
        ),
        20,
    )

    likes = min(
        int(
            counts.get(
                "likes",
                0,
            ) or 0
        ),
        20,
    )

    favorites = min(
        int(
            counts.get(
                "favorites",
                0,
            ) or 0
        ),
        20,
    )

    ratings = min(
        int(
            counts.get(
                "ratings",
                0,
            ) or 0
        ),
        20,
    )

    confidence = (
        watch * 0.20
        + likes * 0.30
        + favorites * 0.40
        + ratings * 0.30
    )

    return round(
        min(confidence, 12.0),
        6,
    )


def _intent_component(
    context,
    candidate,
):
    intent = (
        context.current_intent
        or ""
    ).strip().lower()

    if not intent:
        return 0.0

    matches = 0

    for slug in candidate.genre_matches:
        normalized = (
            slug.replace(
                "-",
                " ",
            )
            .replace(
                "_",
                " ",
            )
            .lower()
        )

        if (
            normalized
            and normalized in intent
        ):
            matches += 1

    if matches:
        return min(
            20.0,
            12.0
            + (
                max(
                    matches - 1,
                    0,
                )
                * 4.0
            ),
        )

    # Presence of a current intent is significant,
    # but no semantic match must be invented.
    return 0.0


def _quality_component(candidate):
    """
    G5-2E currently receives no dedicated rating/quality feature
    in Candidate.

    We therefore use only the existing popularity signal as a
    conservative quality proxy. No unavailable metric is invented.
    """

    return round(
        _clamp(
            candidate.popularity_score
        )
        * 0.08,
        6,
    )


def _trend_component(candidate):
    score = (
        _clamp(
            candidate.trending_score
        )
        * 0.10
    )

    if (
        "top10" in candidate.sources
        and candidate.top10_position
        is not None
    ):
        score += max(
            0.0,
            11.0
            - float(
                candidate.top10_position
            ),
        )

    return round(
        min(score, 20.0),
        6,
    )


def _discovery_component(
    context,
    candidate,
):
    """
    Small exploration bonus for globally discoverable candidates
    without a known preferred-genre match.

    Diversity/exploration policy itself belongs to G5-2F.
    """

    preferred = set(
        _preferred_genre_weights(
            context
        )
    )

    matched = bool(
        preferred.intersection(
            candidate.genre_matches
        )
    )

    if matched:
        return 0.0

    if (
        "trending" in candidate.sources
        or "popular" in candidate.sources
        or "top10" in candidate.sources
    ):
        return 3.0

    return 0.0


def score_candidate(
    *,
    context,
    candidate,
):
    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise RankingError(
            "context must be an EkeAIUserContext."
        )

    if not isinstance(
        candidate,
        Candidate,
    ):
        raise RankingError(
            "candidate must be a Candidate."
        )

    preference = _preference_component(
        context,
        candidate,
    )

    behavior = _behavior_component(
        context
    )

    intent = _intent_component(
        context,
        candidate,
    )

    quality = _quality_component(
        candidate
    )

    trend = _trend_component(
        candidate
    )

    discovery = _discovery_component(
        context,
        candidate,
    )

    components = RankingComponents(
        preference=preference,
        behavior=behavior,
        intent=intent,
        quality=quality,
        trend=trend,
        discovery=discovery,
    )

    reasons = []

    if preference > 0:
        reasons.append(
            "preference"
        )

    if behavior > 0:
        reasons.append(
            "behavior_confidence"
        )

    if intent > 0:
        reasons.append(
            "current_intent"
        )

    if quality > 0:
        reasons.append(
            "quality"
        )

    if trend > 0:
        reasons.append(
            "trend"
        )

    if discovery > 0:
        reasons.append(
            "discovery"
        )

    return RankedCandidate(
        content_id=candidate.content_id,
        score=components.total,
        components=components,
        reasons=tuple(reasons),
        sources=candidate.sources,
    )


def rank_candidates(
    *,
    context,
    candidates,
    limit=20,
):
    try:
        limit = int(limit)
    except (TypeError, ValueError) as exc:
        raise RankingError(
            "limit must be an integer."
        ) from exc

    if limit < 1 or limit > 100:
        raise RankingError(
            "limit must be between 1 and 100."
        )

    ranked = [
        score_candidate(
            context=context,
            candidate=candidate,
        )
        for candidate in candidates
    ]

    ranked.sort(
        key=lambda item: (
            -item.score,
            item.content_id,
        )
    )

    return tuple(
        ranked[:limit]
    )
