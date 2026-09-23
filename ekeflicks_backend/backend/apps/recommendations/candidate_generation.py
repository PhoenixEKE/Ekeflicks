"""
G5-2C — EKE IA candidate generation.

This layer builds a bounded candidate pool for later personalized
ranking.

Important architectural rules:
- PostgreSQL eligibility is applied before any content becomes a candidate.
- Candidate generation is retrieval, not final ranking.
- Current user context influences which retrieval sources are queried.
- Top 10 is a discovery signal, not a personal recommendation.
- Like and Favorite remain independent upstream signals.
- Already watched contents are excluded from recommendation candidates.
- No candidate is fabricated.
"""

from dataclasses import asdict, dataclass, field

from apps.recommendations.eke_ai import (
    eligible_content_queryset,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)
from core.models.recommendations import Top10Entry


EKE_AI_CANDIDATE_VERSION = "g5_2c_v1"


class CandidateGenerationError(ValueError):
    """Raised when candidate generation input is invalid."""


@dataclass(frozen=True)
class Candidate:
    content_id: str
    sources: tuple = field(default_factory=tuple)
    genre_matches: tuple = field(default_factory=tuple)
    trending_score: float = 0.0
    popularity_score: float = 0.0
    top10_position: int | None = None

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class CandidatePool:
    version: str
    profile_id: str
    candidates: tuple
    source_counts: dict

    def to_dict(self):
        return {
            "version": self.version,
            "profile_id": self.profile_id,
            "candidate_count": len(self.candidates),
            "candidates": [
                candidate.to_dict()
                for candidate in self.candidates
            ],
            "source_counts": dict(
                self.source_counts
            ),
        }


def _normalize_limit(limit):
    try:
        value = int(limit)
    except (TypeError, ValueError) as exc:
        raise CandidateGenerationError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > 200:
        raise CandidateGenerationError(
            "limit must be between 1 and 200."
        )

    return value


def _candidate_record(
    *,
    content,
    source,
    genre_matches=(),
    top10_position=None,
):
    return {
        "content_id": str(content.id),
        "sources": {source},
        "genre_matches": set(genre_matches),
        "trending_score": float(
            content.trending_score or 0
        ),
        "popularity_score": float(
            content.popularity_score or 0
        ),
        "top10_position": top10_position,
    }


def _merge_candidate(
    pool,
    *,
    content,
    source,
    genre_matches=(),
    top10_position=None,
):
    content_id = str(content.id)

    if content_id not in pool:
        pool[content_id] = _candidate_record(
            content=content,
            source=source,
            genre_matches=genre_matches,
            top10_position=top10_position,
        )
        return

    current = pool[content_id]
    current["sources"].add(source)
    current["genre_matches"].update(
        genre_matches
    )

    if top10_position is not None:
        previous = current["top10_position"]

        if (
            previous is None
            or top10_position < previous
        ):
            current["top10_position"] = (
                top10_position
            )


def _preferred_genre_slugs(context):
    return tuple(
        preference.slug
        for preference in context.preferred_genres
        if preference.slug
    )


def generate_candidate_pool(
    *,
    context,
    limit=100,
):
    """
    Build a candidate pool from PostgreSQL-authorized contents.

    Retrieval sources:
    - preferred genres;
    - trending;
    - popular;
    - currently published global Top 10.

    The resulting order is deterministic retrieval ordering only.
    Personalized scoring/ranking belongs to G5-2D/G5-2E.
    """

    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise CandidateGenerationError(
            "context must be an EkeAIUserContext."
        )

    limit = _normalize_limit(limit)

    excluded_ids = set(
        context.watched_content_ids
    )

    eligible = (
        eligible_content_queryset()
        .prefetch_related(
            "genres",
        )
    )

    if excluded_ids:
        eligible = eligible.exclude(
            id__in=excluded_ids,
        )

    candidate_map = {}
    source_counts = {
        "preferred_genres": 0,
        "trending": 0,
        "popular": 0,
        "top10": 0,
    }

    genre_slugs = _preferred_genre_slugs(
        context
    )

    if genre_slugs:
        genre_contents = (
            eligible
            .filter(
                genres__slug__in=genre_slugs,
            )
            .distinct()
            .order_by(
                "-trending_score",
                "-popularity_score",
                "id",
            )[:limit]
        )

        for content in genre_contents:
            matches = tuple(
                sorted(
                    {
                        genre.slug
                        for genre
                        in content.genres.all()
                        if genre.slug
                        in genre_slugs
                    }
                )
            )

            _merge_candidate(
                candidate_map,
                content=content,
                source="preferred_genres",
                genre_matches=matches,
            )

            source_counts[
                "preferred_genres"
            ] += 1

    trending_contents = (
        eligible
        .order_by(
            "-trending_score",
            "-popularity_score",
            "id",
        )[:limit]
    )

    for content in trending_contents:
        _merge_candidate(
            candidate_map,
            content=content,
            source="trending",
        )
        source_counts["trending"] += 1

    popular_contents = (
        eligible
        .order_by(
            "-popularity_score",
            "-trending_score",
            "id",
        )[:limit]
    )

    for content in popular_contents:
        _merge_candidate(
            candidate_map,
            content=content,
            source="popular",
        )
        source_counts["popular"] += 1

    eligible_ids = set(
        eligible.values_list(
            "id",
            flat=True,
        )
    )

    top10_rows = (
        Top10Entry.objects
        .filter(
            snapshot__is_published=True,
            snapshot__scope="global",
            content_id__in=eligible_ids,
        )
        .select_related(
            "content",
            "snapshot",
        )
        .order_by(
            "-snapshot__generated_at",
            "position",
            "id",
        )
    )

    seen_top10_contents = set()

    for entry in top10_rows:
        content_id = str(
            entry.content_id
        )

        if content_id in seen_top10_contents:
            continue

        seen_top10_contents.add(
            content_id
        )

        _merge_candidate(
            candidate_map,
            content=entry.content,
            source="top10",
            top10_position=int(
                entry.position
            ),
        )

        source_counts["top10"] += 1

        if (
            source_counts["top10"]
            >= min(limit, 10)
        ):
            break

    def retrieval_key(item):
        sources = item["sources"]

        source_priority = min(
            (
                {
                    "preferred_genres": 0,
                    "top10": 1,
                    "trending": 2,
                    "popular": 3,
                }[source]
                for source in sources
            ),
            default=99,
        )

        top10_position = (
            item["top10_position"]
            if item["top10_position"]
            is not None
            else 999
        )

        return (
            source_priority,
            top10_position,
            -len(
                item["genre_matches"]
            ),
            -item["trending_score"],
            -item["popularity_score"],
            item["content_id"],
        )

    ordered = sorted(
        candidate_map.values(),
        key=retrieval_key,
    )[:limit]

    candidates = tuple(
        Candidate(
            content_id=item[
                "content_id"
            ],
            sources=tuple(
                sorted(
                    item["sources"]
                )
            ),
            genre_matches=tuple(
                sorted(
                    item[
                        "genre_matches"
                    ]
                )
            ),
            trending_score=item[
                "trending_score"
            ],
            popularity_score=item[
                "popularity_score"
            ],
            top10_position=item[
                "top10_position"
            ],
        )
        for item in ordered
    )

    return CandidatePool(
        version=EKE_AI_CANDIDATE_VERSION,
        profile_id=context.profile_id,
        candidates=candidates,
        source_counts=source_counts,
    )
