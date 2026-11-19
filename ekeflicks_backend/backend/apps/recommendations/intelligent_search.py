"""
G5-2G — EKE IA intelligent catalogue search.

Responsibilities:
- understand a textual catalogue query with deterministic lexical signals;
- search only PostgreSQL-authorized catalogue content;
- score title, original title, description and genres;
- optionally use profile preferences and current intent as secondary signals;
- never invent catalogue entries;
- never bypass rights/availability;
- return transparent search reasons.

Semantic/LLM conversational interpretation belongs to G5-2H.
This module is the grounded V1 intelligent search layer.
"""

import re
import unicodedata
from dataclasses import asdict, dataclass

from django.db.models import Prefetch

from apps.recommendations.eke_ai import (
    eligible_content_queryset,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)


EKE_AI_SEARCH_VERSION = "g5_2g_v1"


class IntelligentSearchError(ValueError):
    """Invalid intelligent-search request."""


@dataclass(frozen=True)
class SearchResult:
    content_id: str
    title: str
    score: float
    reasons: tuple
    matched_terms: tuple

    def to_dict(self):
        payload = asdict(self)
        payload["reasons"] = list(
            self.reasons
        )
        payload["matched_terms"] = list(
            self.matched_terms
        )
        return payload


@dataclass(frozen=True)
class SearchResponse:
    version: str
    query: str
    normalized_query: str
    profile_id: str | None
    results: tuple

    def to_dict(self):
        return {
            "version": self.version,
            "query": self.query,
            "normalized_query": self.normalized_query,
            "profile_id": self.profile_id,
            "result_count": len(
                self.results
            ),
            "results": [
                item.to_dict()
                for item in self.results
            ],
        }


def _normalize_text(value):
    value = str(
        value or ""
    ).strip().lower()

    value = unicodedata.normalize(
        "NFKD",
        value,
    )

    value = "".join(
        char
        for char in value
        if not unicodedata.combining(
            char
        )
    )

    value = re.sub(
        r"[^a-z0-9]+",
        " ",
        value,
    )

    return " ".join(
        value.split()
    )


def _query_terms(query):
    normalized = _normalize_text(
        query
    )

    if not normalized:
        raise IntelligentSearchError(
            "query must not be empty."
        )

    terms = tuple(
        dict.fromkeys(
            term
            for term in normalized.split()
            if len(term) >= 2
        )
    )

    if not terms:
        raise IntelligentSearchError(
            "query has no searchable terms."
        )

    return normalized, terms


def _normalize_limit(limit):
    try:
        value = int(limit)
    except (TypeError, ValueError) as exc:
        raise IntelligentSearchError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > 50:
        raise IntelligentSearchError(
            "limit must be between 1 and 50."
        )

    return value


def _preferred_genres(context):
    if context is None:
        return set()

    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise IntelligentSearchError(
            "context must be an EkeAIUserContext."
        )

    return {
        item.slug
        for item in context.preferred_genres
    }


def _score_content(
    *,
    content,
    normalized_query,
    terms,
    preferred_genres,
):
    title = _normalize_text(
        content.title
    )

    original_title = _normalize_text(
        getattr(
            content,
            "original_title",
            "",
        )
    )

    description = _normalize_text(
        getattr(
            content,
            "description",
            "",
        )
    )

    genre_slugs = tuple(
        genre.slug
        for genre in content.genres.all()
    )

    normalized_genres = {
        _normalize_text(
            slug.replace(
                "-",
                " ",
            )
        ): slug
        for slug in genre_slugs
    }

    score = 0.0
    reasons = []
    matched_terms = set()

    if normalized_query == title:
        score += 100.0
        reasons.append(
            "exact_title"
        )
    elif (
        normalized_query
        and normalized_query in title
    ):
        score += 70.0
        reasons.append(
            "title_phrase"
        )

    if (
        original_title
        and normalized_query
        == original_title
    ):
        score += 80.0
        reasons.append(
            "exact_original_title"
        )
    elif (
        original_title
        and normalized_query
        in original_title
    ):
        score += 55.0
        reasons.append(
            "original_title_phrase"
        )

    for term in terms:
        if term in title:
            score += 22.0
            matched_terms.add(
                term
            )
            if "title_terms" not in reasons:
                reasons.append(
                    "title_terms"
                )

        if (
            original_title
            and term
            in original_title
        ):
            score += 16.0
            matched_terms.add(
                term
            )
            if (
                "original_title_terms"
                not in reasons
            ):
                reasons.append(
                    "original_title_terms"
                )

        if (
            description
            and term
            in description
        ):
            score += 5.0
            matched_terms.add(
                term
            )
            if (
                "description_terms"
                not in reasons
            ):
                reasons.append(
                    "description_terms"
                )

        for normalized_genre in normalized_genres:
            if term in normalized_genre:
                score += 18.0
                matched_terms.add(
                    term
                )
                if "genre_match" not in reasons:
                    reasons.append(
                        "genre_match"
                    )

    genre_preference_matches = (
        set(
            genre_slugs
        )
        & preferred_genres
    )

    if genre_preference_matches:
        score += min(
            len(
                genre_preference_matches
            )
            * 3.0,
            9.0,
        )
        reasons.append(
            "profile_preference"
        )

    # Existing catalogue metrics remain only weak tie-break signals.
    score += min(
        max(
            float(
                getattr(
                    content,
                    "trending_score",
                    0,
                )
                or 0
            ),
            0.0,
        ),
        100.0,
    ) * 0.02

    score += min(
        max(
            float(
                getattr(
                    content,
                    "popularity_score",
                    0,
                )
                or 0
            ),
            0.0,
        ),
        100.0,
    ) * 0.01

    return (
        round(
            score,
            6,
        ),
        tuple(
            dict.fromkeys(
                reasons
            )
        ),
        tuple(
            sorted(
                matched_terms
            )
        ),
    )


def intelligent_search(
    *,
    query,
    context=None,
    limit=20,
):
    normalized_query, terms = (
        _query_terms(
            query
        )
    )

    limit = _normalize_limit(
        limit
    )

    preferred_genres = (
        _preferred_genres(
            context
        )
    )

    queryset = (
        eligible_content_queryset()
        .prefetch_related(
            "genres"
        )
        .order_by(
            "id"
        )
    )

    scored = []

    for content in queryset:
        score, reasons, matched_terms = (
            _score_content(
                content=content,
                normalized_query=normalized_query,
                terms=terms,
                preferred_genres=preferred_genres,
            )
        )

        # No lexical match => do not invent a result.
        if not matched_terms and not any(
            reason
            in {
                "exact_title",
                "title_phrase",
                "exact_original_title",
                "original_title_phrase",
            }
            for reason in reasons
        ):
            continue

        scored.append(
            SearchResult(
                content_id=str(
                    content.id
                ),
                title=content.title,
                score=score,
                reasons=reasons,
                matched_terms=matched_terms,
            )
        )

    scored.sort(
        key=lambda item: (
            -item.score,
            item.title.lower(),
            item.content_id,
        )
    )

    return SearchResponse(
        version=EKE_AI_SEARCH_VERSION,
        query=str(
            query
        ),
        normalized_query=normalized_query,
        profile_id=(
            context.profile_id
            if context
            else None
        ),
        results=tuple(
            scored[:limit]
        ),
    )
