"""
G5-2I — Grounded recommendation explanations.

Rules:
- explanations come only from real recommendation reasons;
- catalogue data remains PostgreSQL-authoritative;
- profile claims are emitted only when supported by context/data;
- unknown reasons are omitted instead of being invented;
- no database writes;
- deterministic output.
"""

import re
from dataclasses import dataclass

from django.core.exceptions import ValidationError as DjangoValidationError

from apps.recommendations.candidate_generation import (
    generate_candidate_pool,
)
from apps.recommendations.eke_ai import (
    eligible_content_queryset,
)
from apps.recommendations.personalized_engine import (
    recommend_for_context,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)


EKE_AI_EXPLANATION_VERSION = "g5_2i_v1"


class RecommendationExplanationError(ValueError):
    """Invalid or unsupported recommendation explanation request."""


@dataclass(frozen=True)
class ExplanationSignal:
    code: str
    text: str

    def to_dict(self):
        return {
            "code": self.code,
            "text": self.text,
        }


@dataclass(frozen=True)
class RecommendationExplanation:
    version: str
    content_id: str
    title: str
    headline: str
    recommendation_score: float | None
    source_reasons: tuple
    signals: tuple

    def to_dict(self):
        return {
            "version": self.version,
            "content_id": self.content_id,
            "title": self.title,
            "headline": self.headline,
            "recommendation_score": self.recommendation_score,
            "source_reasons": list(
                self.source_reasons
            ),
            "signals": [
                signal.to_dict()
                for signal in self.signals
            ],
        }


def _normalize_reason(value):
    value = str(
        value or ""
    ).strip().lower()

    value = re.sub(
        r"[^a-z0-9]+",
        "_",
        value,
    )

    return value.strip("_")


def _content_genres(content):
    return {
        str(genre.slug)
        for genre in content.genres.all()
        if getattr(
            genre,
            "slug",
            None,
        )
    }


def _preferred_genres(context):
    return {
        str(item.slug)
        for item in context.preferred_genres
        if getattr(
            item,
            "slug",
            None,
        )
    }


def _append_signal(
    signals,
    seen,
    *,
    code,
    text,
):
    if code in seen:
        return

    seen.add(
        code
    )

    signals.append(
        ExplanationSignal(
            code=code,
            text=text,
        )
    )


def build_recommendation_explanation(
    *,
    context,
    recommendation,
    content,
):
    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise RecommendationExplanationError(
            "context must be an EkeAIUserContext."
        )

    recommendation_id = str(
        getattr(
            recommendation,
            "content_id",
            "",
        )
    )

    content_id = str(
        getattr(
            content,
            "id",
            "",
        )
    )

    if not recommendation_id:
        raise RecommendationExplanationError(
            "recommendation content_id is required."
        )

    if recommendation_id != content_id:
        raise RecommendationExplanationError(
            "recommendation/content mismatch."
        )

    raw_reasons = tuple(
        str(reason)
        for reason in (
            getattr(
                recommendation,
                "reasons",
                (),
            )
            or ()
        )
        if str(reason).strip()
    )

    normalized_reasons = tuple(
        _normalize_reason(
            reason
        )
        for reason in raw_reasons
    )

    content_genres = _content_genres(
        content
    )

    preferred_genres = _preferred_genres(
        context
    )

    matching_preferred_genres = (
        content_genres
        & preferred_genres
    )

    signals = []
    seen = set()

    for reason in normalized_reasons:
        if not reason:
            continue

        if (
            (
                "preference" in reason
                or "preferred" in reason
                or "genre_match" in reason
            )
            and matching_preferred_genres
        ):
            _append_signal(
                signals,
                seen,
                code="preferred_genre",
                text=(
                    "This title matches genres "
                    "you prefer."
                ),
            )

        if (
            "trend" in reason
            and float(
                getattr(
                    content,
                    "trending_score",
                    0,
                )
                or 0
            ) > 0
        ):
            _append_signal(
                signals,
                seen,
                code="trending",
                text=(
                    "This title is currently "
                    "trending in the catalogue."
                ),
            )

        if (
            (
                "popular" in reason
                or "popularity" in reason
            )
            and float(
                getattr(
                    content,
                    "popularity_score",
                    0,
                )
                or 0
            ) > 0
        ):
            _append_signal(
                signals,
                seen,
                code="popular",
                text=(
                    "This title is receiving "
                    "strong catalogue interest."
                ),
            )

        if (
            "top10" in reason
            or "top_10" in reason
        ):
            _append_signal(
                signals,
                seen,
                code="top10",
                text=(
                    "This title is supported "
                    "by the current Top 10 signal."
                ),
            )

        if (
            "discover" in reason
            or "explor" in reason
        ):
            _append_signal(
                signals,
                seen,
                code="discovery",
                text=(
                    "This title is included "
                    "to broaden your discovery."
                ),
            )

        if (
            "intent" in reason
            and str(
                context.current_intent
                or ""
            ).strip()
        ):
            _append_signal(
                signals,
                seen,
                code="current_intent",
                text=(
                    "This recommendation reflects "
                    "what you are looking for right now."
                ),
            )

        if (
            "history" in reason
            or "watched" in reason
            or "watch_history" in reason
        ):
            _append_signal(
                signals,
                seen,
                code="watch_history",
                text=(
                    "This recommendation is supported "
                    "by your viewing history."
                ),
            )

        if "favorite" in reason:
            _append_signal(
                signals,
                seen,
                code="favorites",
                text=(
                    "This recommendation is supported "
                    "by your favorites."
                ),
            )

        if (
            "like" in reason
            and "unlike" not in reason
        ):
            _append_signal(
                signals,
                seen,
                code="likes",
                text=(
                    "This recommendation is supported "
                    "by titles you liked."
                ),
            )

        if "rating" in reason:
            _append_signal(
                signals,
                seen,
                code="ratings",
                text=(
                    "This recommendation is supported "
                    "by your rating signals."
                ),
            )

        if (
            "similar" in reason
            or "similarity" in reason
        ):
            _append_signal(
                signals,
                seen,
                code="similarity",
                text=(
                    "This title is related to content "
                    "already identified as relevant "
                    "for your profile."
                ),
            )

    if signals:
        headline = signals[0].text
    else:
        headline = (
            "This title was selected by your "
            "current personalized recommendation "
            "pipeline."
        )

    score = getattr(
        recommendation,
        "score",
        None,
    )

    if score is not None:
        score = float(
            score
        )

    return RecommendationExplanation(
        version=EKE_AI_EXPLANATION_VERSION,
        content_id=content_id,
        title=str(
            content.title
        ),
        headline=headline,
        recommendation_score=score,
        source_reasons=raw_reasons,
        signals=tuple(
            signals
        ),
    )


def explain_personalized_recommendation(
    *,
    context,
    content_id,
):
    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise RecommendationExplanationError(
            "context must be an EkeAIUserContext."
        )

    content_id = str(
        content_id or ""
    ).strip()

    if not content_id:
        raise RecommendationExplanationError(
            "content_id is required."
        )

    try:
        content = (
            eligible_content_queryset()
            .prefetch_related(
                "genres"
            )
            .filter(
                id=content_id
            )
            .first()
        )

    except (
        ValueError,
        TypeError,
        DjangoValidationError,
    ) as exc:
        raise RecommendationExplanationError(
            "invalid content_id."
        ) from exc

    if content is None:
        raise RecommendationExplanationError(
            "content is not currently eligible."
        )

    pool = generate_candidate_pool(
        context=context,
        limit=100,
    )

    result = recommend_for_context(
        context=context,
        candidate_pool=pool,
        limit=100,
    )

    recommendation = next(
        (
            item
            for item
            in result.recommendations
            if str(
                item.content_id
            ) == content_id
        ),
        None,
    )

    if recommendation is None:
        raise RecommendationExplanationError(
            "content is not in the current "
            "personalized recommendations."
        )

    return build_recommendation_explanation(
        context=context,
        recommendation=recommendation,
        content=content,
    )
