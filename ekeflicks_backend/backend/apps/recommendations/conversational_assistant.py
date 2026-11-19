"""
G5-2H — EKE IA conversational assistant.

V1 responsibilities:
- interpret a user message into a grounded catalogue intent;
- orchestrate intelligent search or personalized recommendation;
- reuse the authenticated user context;
- return only PostgreSQL-authorized catalogue items;
- never fabricate content, titles, reasons or availability;
- remain deterministic and testable.

The assistant orchestrates existing EKE IA services.
It does not replace PostgreSQL authorization and does not write user data.
"""

import re
import unicodedata
from dataclasses import dataclass

from apps.recommendations.candidate_generation import (
    generate_candidate_pool,
)
from apps.recommendations.eke_ai import (
    eligible_content_queryset,
)
from apps.recommendations.intelligent_search import (
    intelligent_search,
)
from apps.recommendations.personalized_engine import (
    recommend_for_context,
)
from apps.recommendations.user_context import (
    EkeAIUserContext,
)


EKE_AI_CONVERSATIONAL_VERSION = "g5_2h_v1"


class ConversationalAssistantError(ValueError):
    """Invalid conversational assistant request."""


@dataclass(frozen=True)
class ConversationItem:
    content_id: str
    title: str
    score: float | None
    reasons: tuple

    def to_dict(self):
        return {
            "content_id": self.content_id,
            "title": self.title,
            "score": self.score,
            "reasons": list(
                self.reasons
            ),
        }


@dataclass(frozen=True)
class ConversationResponse:
    version: str
    intent: str
    message: str
    reply: str
    profile_id: str
    items: tuple

    def to_dict(self):
        return {
            "version": self.version,
            "intent": self.intent,
            "message": self.message,
            "reply": self.reply,
            "profile_id": self.profile_id,
            "item_count": len(
                self.items
            ),
            "items": [
                item.to_dict()
                for item in self.items
            ],
        }


_SEARCH_MARKERS = {
    "find",
    "search",
    "look",
    "show",
    "where",
    "cherche",
    "chercher",
    "trouve",
    "trouver",
    "montre",
    "affiche",
}

_RECOMMENDATION_MARKERS = {
    "recommend",
    "recommendation",
    "recommendations",
    "suggest",
    "suggestion",
    "suggestions",
    "watch",
    "regarder",
    "conseille",
    "conseiller",
    "recommande",
    "recommandation",
    "propose",
    "proposer",
}

_HELP_MARKERS = {
    "help",
    "aide",
    "bonjour",
    "hello",
    "salut",
    "hi",
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


def _normalize_limit(limit):
    try:
        value = int(
            limit
        )
    except (
        TypeError,
        ValueError,
    ) as exc:
        raise ConversationalAssistantError(
            "limit must be an integer."
        ) from exc

    if value < 1 or value > 20:
        raise ConversationalAssistantError(
            "limit must be between 1 and 20."
        )

    return value


def classify_intent(message):
    normalized = _normalize_text(
        message
    )

    if not normalized:
        raise ConversationalAssistantError(
            "message must not be empty."
        )

    words = set(
        normalized.split()
    )

    recommendation_score = len(
        words
        & _RECOMMENDATION_MARKERS
    )

    search_score = len(
        words
        & _SEARCH_MARKERS
    )

    help_score = len(
        words
        & _HELP_MARKERS
    )

    recommendation_phrases = (
        "what should i watch",
        "que regarder",
        "quoi regarder",
        "tu me conseilles",
        "tu me recommandes",
        "recommend me",
    )

    search_phrases = (
        "do you have",
        "avez vous",
        "as tu",
        "est ce que vous avez",
    )

    if any(
        phrase in normalized
        for phrase in recommendation_phrases
    ):
        recommendation_score += 3

    if any(
        phrase in normalized
        for phrase in search_phrases
    ):
        search_score += 2

    if recommendation_score > search_score:
        return "recommendation"

    if search_score > 0:
        return "search"

    if (
        help_score > 0
        and len(words) <= 4
    ):
        return "help"

    # Grounded default:
    # an unknown catalogue-oriented sentence becomes search,
    # never an invented conversational answer.
    return "search"


def _titles_for_ids(content_ids):
    if not content_ids:
        return {}

    rows = (
        eligible_content_queryset()
        .filter(
            id__in=content_ids
        )
        .values_list(
            "id",
            "title",
        )
    )

    return {
        str(content_id): title
        for content_id, title
        in rows
    }


def _search_items(
    *,
    message,
    context,
    limit,
):
    result = intelligent_search(
        query=message,
        context=context,
        limit=limit,
    )

    return tuple(
        ConversationItem(
            content_id=item.content_id,
            title=item.title,
            score=item.score,
            reasons=item.reasons,
        )
        for item in result.results
    )


def _recommendation_items(
    *,
    context,
    limit,
):
    candidate_limit = min(
        max(
            limit * 5,
            20,
        ),
        100,
    )

    pool = generate_candidate_pool(
        context=context,
        limit=candidate_limit,
    )

    result = recommend_for_context(
        context=context,
        candidate_pool=pool,
        limit=limit,
    )

    recommendation_ids = [
        item.content_id
        for item in result.recommendations
    ]

    titles = _titles_for_ids(
        recommendation_ids
    )

    items = []

    for item in result.recommendations:
        title = titles.get(
            item.content_id
        )

        # Authorization/content consistency guard.
        # If an id is no longer eligible between pipeline steps,
        # it is not exposed.
        if title is None:
            continue

        items.append(
            ConversationItem(
                content_id=item.content_id,
                title=title,
                score=item.score,
                reasons=item.reasons,
            )
        )

    return tuple(
        items
    )


def _reply_for(
    *,
    intent,
    items,
):
    if intent == "help":
        return (
            "I can search the available catalogue "
            "or recommend content based on your profile."
        )

    if items:
        if intent == "recommendation":
            return (
                "Here are recommendations selected "
                "from the currently available catalogue."
            )

        return (
            "Here are the available catalogue results "
            "that match your request."
        )

    if intent == "recommendation":
        return (
            "I do not have an available recommendation "
            "for this profile right now."
        )

    return (
        "I could not find an available catalogue item "
        "matching this request."
    )


def converse(
    *,
    message,
    context,
    limit=10,
):
    if not isinstance(
        context,
        EkeAIUserContext,
    ):
        raise ConversationalAssistantError(
            "context must be an EkeAIUserContext."
        )

    normalized_message = str(
        message or ""
    ).strip()

    if not normalized_message:
        raise ConversationalAssistantError(
            "message must not be empty."
        )

    limit = _normalize_limit(
        limit
    )

    intent = classify_intent(
        normalized_message
    )

    if intent == "help":
        items = tuple()

    elif intent == "recommendation":
        items = _recommendation_items(
            context=context,
            limit=limit,
        )

    else:
        items = _search_items(
            message=normalized_message,
            context=context,
            limit=limit,
        )

    return ConversationResponse(
        version=EKE_AI_CONVERSATIONAL_VERSION,
        intent=intent,
        message=normalized_message,
        reply=_reply_for(
            intent=intent,
            items=items,
        ),
        profile_id=context.profile_id,
        items=items,
    )
