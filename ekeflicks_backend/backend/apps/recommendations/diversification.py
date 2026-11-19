"""
G5-2F — EKE IA diversity / discovery / exploration.

This layer runs AFTER G5-2E ranking.

Responsibilities:
- preserve the strongest ranked recommendation;
- reduce repetitive genre concentration;
- allow controlled discovery/exploration;
- remain deterministic;
- never create a candidate that was not supplied upstream;
- never change PostgreSQL eligibility;
- never rewrite the G5-2E ranking score.

The ranking score remains owned by G5-2E.
This module only determines the final ordering of already-ranked,
already-authorized candidates.
"""

from apps.recommendations.candidate_generation import (
    Candidate,
)
from apps.recommendations.ranking import (
    RankedCandidate,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)


EKE_AI_DIVERSIFICATION_VERSION = "g5_2f_v1"


class DiversificationError(ValueError):
    """Invalid diversity/exploration request."""


def _normalize_limit(limit):
    try:
        value = int(limit)
    except (TypeError, ValueError) as exc:
        raise DiversificationError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > 100:
        raise DiversificationError(
            "limit must be between 1 and 100."
        )

    return value


def _candidate_lookup(candidates):
    lookup = {}

    for candidate in candidates:
        if not isinstance(
            candidate,
            Candidate,
        ):
            raise DiversificationError(
                "candidates must contain Candidate instances."
            )

        if candidate.content_id not in lookup:
            lookup[
                candidate.content_id
            ] = candidate

    return lookup


def _genre_set(candidate):
    return set(
        candidate.genre_matches or ()
    )


def _is_exploration_candidate(
    ranked_item,
):
    return (
        "discovery" in ranked_item.reasons
        or "trending" in ranked_item.sources
        or "popular" in ranked_item.sources
        or "top10" in ranked_item.sources
    )


def diversify_ranked_candidates(
    *,
    context,
    ranked_candidates,
    candidates,
    limit=20,
):
    """
    Deterministic post-ranking diversification.

    Strategy:
    1. Keep the original #1 recommendation untouched.
    2. For subsequent positions, prefer:
       - unseen genres;
       - controlled discovery candidates;
       - high original ranking score.
    3. Penalize repeated genre concentration.
    4. Never fabricate or introduce a new content id.

    G5-2F does not alter RankedCandidate.score.
    """

    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise DiversificationError(
            "context must be an EkeAIUserContext."
        )

    limit = _normalize_limit(
        limit
    )

    ranked = tuple(
        ranked_candidates
    )

    for item in ranked:
        if not isinstance(
            item,
            RankedCandidate,
        ):
            raise DiversificationError(
                "ranked_candidates must contain RankedCandidate instances."
            )

    if not ranked:
        return tuple()

    lookup = _candidate_lookup(
        candidates
    )

    # Only candidates known to the authorized upstream pool
    # may survive this stage.
    remaining = [
        item
        for item in ranked
        if item.content_id in lookup
    ]

    if not remaining:
        return tuple()

    # Strongest personalized/ranked result is protected.
    selected = [
        remaining.pop(0)
    ]

    genre_counts = {}

    for genre in _genre_set(
        lookup[selected[0].content_id]
    ):
        genre_counts[genre] = (
            genre_counts.get(
                genre,
                0,
            )
            + 1
        )

    while (
        remaining
        and len(selected) < limit
    ):
        best_index = None
        best_key = None

        for index, item in enumerate(
            remaining
        ):
            candidate = lookup[
                item.content_id
            ]

            genres = _genre_set(
                candidate
            )

            unseen_genres = sum(
                1
                for genre in genres
                if genre_counts.get(
                    genre,
                    0,
                ) == 0
            )

            repetition = sum(
                genre_counts.get(
                    genre,
                    0,
                )
                for genre in genres
            )

            exploration = (
                1
                if _is_exploration_candidate(
                    item
                )
                else 0
            )

            # Diversity is deliberately bounded:
            # ranking remains the dominant signal.
            diversity_adjustment = (
                unseen_genres * 4.0
                + exploration * 1.5
                - repetition * 3.0
            )

            adjusted_score = (
                float(item.score)
                + diversity_adjustment
            )

            # Deterministic tie-break:
            # adjusted score, original score, content id.
            key = (
                adjusted_score,
                float(item.score),
                str(item.content_id),
            )

            if (
                best_key is None
                or key > best_key
            ):
                best_key = key
                best_index = index

        chosen = remaining.pop(
            best_index
        )

        selected.append(
            chosen
        )

        for genre in _genre_set(
            lookup[chosen.content_id]
        ):
            genre_counts[genre] = (
                genre_counts.get(
                    genre,
                    0,
                )
                + 1
            )

    return tuple(
        selected[:limit]
    )
