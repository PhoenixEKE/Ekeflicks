"""
G5-2J — EKE IA explicit feedback / behavioral learning.

The service uses existing interaction models only:
- Like
- Favorite
- Rating

No parallel feedback database is introduced.

Flow:
user feedback
    -> PostgreSQL interaction
    -> rebuild EKE IA context
    -> signal becomes available to future recommendations

Rules:
- authenticated user/profile scope only;
- PostgreSQL remains authoritative;
- only currently eligible catalogue content can receive EKE IA feedback;
- idempotent like/favorite operations;
- deterministic rating updates;
- no fabricated behavioral signal.
"""

from dataclasses import dataclass

from django.core.exceptions import ValidationError as DjangoValidationError

from core.models import (
    Favorite,
    Like,
    Rating,
)

from apps.recommendations.eke_ai import (
    eligible_content_queryset,
)
from apps.recommendations.user_context import (
    EkeAIContextError,
    build_user_context,
)


EKE_AI_FEEDBACK_VERSION = "g5_2j_v1"


class FeedbackLearningError(ValueError):
    """Invalid EKE IA feedback operation."""


_ALLOWED_ACTIONS = {
    "like",
    "unlike",
    "favorite",
    "unfavorite",
    "rate",
    "clear_rating",
}


@dataclass(frozen=True)
class FeedbackResult:
    version: str
    action: str
    content_id: str
    profile_id: str
    changed: bool
    liked: bool
    favorited: bool
    rating: float | None
    signal_counts: dict

    def to_dict(self):
        return {
            "version": self.version,
            "action": self.action,
            "content_id": self.content_id,
            "profile_id": self.profile_id,
            "changed": self.changed,
            "state": {
                "liked": self.liked,
                "favorited": self.favorited,
                "rating": self.rating,
            },
            "signal_counts": dict(
                self.signal_counts
            ),
        }


def _normalize_action(action):
    normalized = str(
        action or ""
    ).strip().lower()

    if normalized not in _ALLOWED_ACTIONS:
        raise FeedbackLearningError(
            "unsupported feedback action."
        )

    return normalized


def _normalize_rating(value):
    if value is None:
        raise FeedbackLearningError(
            "rating is required for rate action."
        )

    try:
        rating = float(
            value
        )
    except (
        TypeError,
        ValueError,
    ) as exc:
        raise FeedbackLearningError(
            "rating must be numeric."
        ) from exc

    if rating < 1 or rating > 5:
        raise FeedbackLearningError(
            "rating must be between 1 and 5."
        )

    return rating


def _resolve_content(content_id):
    value = str(
        content_id or ""
    ).strip()

    if not value:
        raise FeedbackLearningError(
            "content_id is required."
        )

    try:
        content = (
            eligible_content_queryset()
            .filter(
                id=value
            )
            .first()
        )

    except (
        ValueError,
        TypeError,
        DjangoValidationError,
    ) as exc:
        raise FeedbackLearningError(
            "invalid content_id."
        ) from exc

    if content is None:
        raise FeedbackLearningError(
            "content is not currently eligible."
        )

    return content


def _resolve_profile(
    *,
    user,
    profile_id,
):
    try:
        context = build_user_context(
            user=user,
            profile_id=profile_id,
            current_intent="feedback",
        )

    except EkeAIContextError:
        raise

    profile = (
        user.profiles
        .filter(
            id=context.profile_id,
            is_active=True,
        )
        .first()
    )

    if profile is None:
        raise FeedbackLearningError(
            "active profile not found."
        )

    return profile


def _current_state(
    *,
    profile,
    content,
):
    rating_obj = (
        Rating.objects
        .filter(
            profile=profile,
            content=content,
        )
        .first()
    )

    rating_value = None

    if rating_obj is not None:
        rating_value = float(
            rating_obj.rating
        )

    return {
        "liked": (
            Like.objects
            .filter(
                profile=profile,
                content=content,
            )
            .exists()
        ),
        "favorited": (
            Favorite.objects
            .filter(
                profile=profile,
                content=content,
            )
            .exists()
        ),
        "rating": rating_value,
    }


def record_feedback(
    *,
    user,
    content_id,
    action,
    profile_id=None,
    rating=None,
):
    action = _normalize_action(
        action
    )

    content = _resolve_content(
        content_id
    )

    profile = _resolve_profile(
        user=user,
        profile_id=profile_id,
    )

    changed = False

    if action == "like":
        _, created = (
            Like.objects
            .get_or_create(
                profile=profile,
                content=content,
            )
        )

        changed = created

    elif action == "unlike":
        deleted, _ = (
            Like.objects
            .filter(
                profile=profile,
                content=content,
            )
            .delete()
        )

        changed = deleted > 0

    elif action == "favorite":
        _, created = (
            Favorite.objects
            .get_or_create(
                profile=profile,
                content=content,
            )
        )

        changed = created

    elif action == "unfavorite":
        deleted, _ = (
            Favorite.objects
            .filter(
                profile=profile,
                content=content,
            )
            .delete()
        )

        changed = deleted > 0

    elif action == "rate":
        value = _normalize_rating(
            rating
        )

        existing = (
            Rating.objects
            .filter(
                profile=profile,
                content=content,
            )
            .first()
        )

        previous = (
            float(
                existing.rating
            )
            if existing is not None
            else None
        )

        Rating.objects.update_or_create(
            profile=profile,
            content=content,
            defaults={
                "rating": value,
            },
        )

        changed = previous != value

    elif action == "clear_rating":
        deleted, _ = (
            Rating.objects
            .filter(
                profile=profile,
                content=content,
            )
            .delete()
        )

        changed = deleted > 0

    state = _current_state(
        profile=profile,
        content=content,
    )

    refreshed_context = build_user_context(
        user=user,
        profile_id=str(
            profile.id
        ),
        current_intent="feedback",
    )

    return FeedbackResult(
        version=EKE_AI_FEEDBACK_VERSION,
        action=action,
        content_id=str(
            content.id
        ),
        profile_id=str(
            profile.id
        ),
        changed=changed,
        liked=state["liked"],
        favorited=state["favorited"],
        rating=state["rating"],
        signal_counts=dict(
            refreshed_context.signal_counts
        ),
    )
