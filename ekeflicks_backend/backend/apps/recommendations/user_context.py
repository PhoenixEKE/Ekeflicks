"""
G5-2B — EKE IA user context.

This module converts authenticated EKEFLICKS profile signals into a
stable, deterministic context consumed by later recommendation stages.

Rules:
- the authenticated user owns the selected profile;
- only active profiles may be used;
- Like and Favorite remain independent signals;
- current intent may be supplied independently from historical signals;
- this layer does not authorize catalogue exposure;
- PostgreSQL eligibility remains a later mandatory candidate gate.
"""

from collections import Counter
from dataclasses import asdict, dataclass, field
from typing import Optional

from core.models import (
    Favorite,
    Like,
    Profile,
    Rating,
    WatchHistory,
)


EKE_AI_USER_CONTEXT_VERSION = "g5_2b_v1"


class EkeAIContextError(ValueError):
    """Base error raised while constructing an EKE IA context."""


class EkeAIAuthenticationRequired(EkeAIContextError):
    """Raised when no authenticated actor is available."""


class EkeAIProfileUnavailable(EkeAIContextError):
    """Raised when the requested active profile is unavailable."""


@dataclass(frozen=True)
class WatchSignal:
    content_id: str
    progress: int
    watched_duration: int
    completed: bool

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class RatingSignal:
    content_id: str
    rating: float

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class GenrePreference:
    slug: str
    weight: int

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class EkeAIUserContext:
    version: str
    user_id: str
    profile_id: str
    profile_name: str

    current_intent: str = ""

    recent_watch_history: tuple = field(
        default_factory=tuple,
    )

    watched_content_ids: tuple = field(
        default_factory=tuple,
    )

    liked_content_ids: tuple = field(
        default_factory=tuple,
    )

    favorite_content_ids: tuple = field(
        default_factory=tuple,
    )

    ratings: tuple = field(
        default_factory=tuple,
    )

    preferred_genres: tuple = field(
        default_factory=tuple,
    )

    signal_counts: dict = field(
        default_factory=dict,
    )

    def to_dict(self):
        return {
            "version": self.version,
            "user_id": self.user_id,
            "profile_id": self.profile_id,
            "profile_name": self.profile_name,
            "current_intent": self.current_intent,
            "recent_watch_history": [
                item.to_dict()
                for item in self.recent_watch_history
            ],
            "watched_content_ids": list(
                self.watched_content_ids
            ),
            "liked_content_ids": list(
                self.liked_content_ids
            ),
            "favorite_content_ids": list(
                self.favorite_content_ids
            ),
            "ratings": [
                item.to_dict()
                for item in self.ratings
            ],
            "preferred_genres": [
                item.to_dict()
                for item in self.preferred_genres
            ],
            "signal_counts": dict(
                self.signal_counts
            ),
        }


def resolve_active_profile(
    *,
    user,
    profile_id=None,
):
    """
    Resolve one active profile owned by the authenticated actor.

    A caller cannot cross the user/profile ownership boundary.
    """

    if (
        user is None
        or not getattr(
            user,
            "is_authenticated",
            False,
        )
    ):
        raise EkeAIAuthenticationRequired(
            "Authentication required for EKE IA context."
        )

    queryset = Profile.objects.filter(
        user=user,
        is_active=True,
    )

    if profile_id:
        profile = queryset.filter(
            pk=profile_id,
        ).first()
    else:
        profile = queryset.order_by(
            "created_at",
            "id",
        ).first()

    if profile is None:
        raise EkeAIProfileUnavailable(
            "No active profile available for this user."
        )

    return profile


def _collect_genre_preferences(
    *,
    watched_ids,
    liked_ids,
    favorite_ids,
    rated_ids,
):
    """
    Build deterministic genre affinities.

    Weighting intentionally remains simple in G5-2B:
    - watched content: 1
    - liked content: 2
    - favorite content: 3
    - rated content: 1

    This is context extraction, not final recommendation ranking.
    """

    from core.models import Content

    weights = Counter()

    signal_groups = (
        (watched_ids, 1),
        (liked_ids, 2),
        (favorite_ids, 3),
        (rated_ids, 1),
    )

    for content_ids, weight in signal_groups:
        if not content_ids:
            continue

        queryset = (
            Content.objects
            .filter(
                id__in=content_ids,
            )
            .prefetch_related(
                "genres",
            )
        )

        for content in queryset:
            for genre in content.genres.all():
                weights[genre.slug] += weight

    return tuple(
        GenrePreference(
            slug=slug,
            weight=weight,
        )
        for slug, weight in sorted(
            weights.items(),
            key=lambda item: (
                -item[1],
                item[0],
            ),
        )
    )


def build_user_context(
    *,
    user,
    profile_id=None,
    current_intent="",
    history_limit=50,
):
    """
    Build the normalized EKE IA context for one active profile.

    No candidate catalogue is exposed here. Candidate generation and
    PostgreSQL eligibility enforcement belong to subsequent phases.
    """

    if history_limit < 1 or history_limit > 200:
        raise EkeAIContextError(
            "history_limit must be between 1 and 200."
        )

    profile = resolve_active_profile(
        user=user,
        profile_id=profile_id,
    )

    watch_rows = list(
        WatchHistory.objects
        .filter(
            profile=profile,
        )
        .select_related(
            "content",
        )
        .order_by(
            "-updated_at",
            "-id",
        )[:history_limit]
    )

    like_rows = list(
        Like.objects
        .filter(
            profile=profile,
        )
        .order_by(
            "-created_at",
            "-id",
        )
    )

    favorite_rows = list(
        Favorite.objects
        .filter(
            profile=profile,
        )
        .order_by(
            "-created_at",
            "-id",
        )
    )

    rating_rows = list(
        Rating.objects
        .filter(
            profile=profile,
        )
        .order_by(
            "-updated_at",
            "-id",
        )
    )

    watched_ids = tuple(
        str(row.content_id)
        for row in watch_rows
    )

    liked_ids = tuple(
        str(row.content_id)
        for row in like_rows
    )

    favorite_ids = tuple(
        str(row.content_id)
        for row in favorite_rows
    )

    rated_ids = tuple(
        str(row.content_id)
        for row in rating_rows
    )

    genre_preferences = (
        _collect_genre_preferences(
            watched_ids=watched_ids,
            liked_ids=liked_ids,
            favorite_ids=favorite_ids,
            rated_ids=rated_ids,
        )
    )

    return EkeAIUserContext(
        version=EKE_AI_USER_CONTEXT_VERSION,
        user_id=str(user.id),
        profile_id=str(profile.id),
        profile_name=profile.name,
        current_intent=(
            current_intent or ""
        ).strip(),
        recent_watch_history=tuple(
            WatchSignal(
                content_id=str(
                    row.content_id
                ),
                progress=int(
                    row.progress or 0
                ),
                watched_duration=int(
                    row.watched_duration or 0
                ),
                completed=bool(
                    row.completed
                ),
            )
            for row in watch_rows
        ),
        watched_content_ids=watched_ids,
        liked_content_ids=liked_ids,
        favorite_content_ids=favorite_ids,
        ratings=tuple(
            RatingSignal(
                content_id=str(
                    row.content_id
                ),
                rating=float(
                    row.rating
                ),
            )
            for row in rating_rows
        ),
        preferred_genres=genre_preferences,
        signal_counts={
            "watch_history":
                len(watch_rows),
            "likes":
                len(like_rows),
            "favorites":
                len(favorite_rows),
            "ratings":
                len(rating_rows),
        },
    )
