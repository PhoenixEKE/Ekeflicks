from django.test import TestCase

from core.models import Content

from apps.recommendations.conversational_assistant import (
    EKE_AI_CONVERSATIONAL_VERSION,
    ConversationalAssistantError,
    classify_intent,
    converse,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
)


class ConversationalAssistantTests(TestCase):
    def _context(self):
        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="chat-user",
            profile_id="chat-profile",
            profile_name="Main",
            current_intent="",
            signal_counts={
                "watch_history": 0,
                "likes": 0,
                "favorites": 0,
                "ratings": 0,
            },
        )

    def _content(
        self,
        *,
        title,
        approved=True,
    ):
        return Content.objects.create(
            title=title,
            description="Grounded assistant test.",
            type="movie",
            producer_submission_status=(
                "approved"
                if approved
                else "draft"
            ),
        )

    def test_search_intent_english(self):
        self.assertEqual(
            classify_intent(
                "Find Night City"
            ),
            "search",
        )

    def test_search_intent_french(self):
        self.assertEqual(
            classify_intent(
                "Trouve Night City"
            ),
            "search",
        )

    def test_recommendation_intent_english(self):
        self.assertEqual(
            classify_intent(
                "What should I watch?"
            ),
            "recommendation",
        )

    def test_recommendation_intent_french(self):
        self.assertEqual(
            classify_intent(
                "Que regarder ?"
            ),
            "recommendation",
        )

    def test_help_intent(self):
        self.assertEqual(
            classify_intent(
                "help"
            ),
            "help",
        )

    def test_unknown_defaults_to_grounded_search(self):
        self.assertEqual(
            classify_intent(
                "Night City"
            ),
            "search",
        )

    def test_empty_message_rejected(self):
        with self.assertRaises(
            ConversationalAssistantError
        ):
            converse(
                message=" ",
                context=self._context(),
            )

    def test_search_returns_authorized_catalogue_item(self):
        content = self._content(
            title="Night City",
        )

        result = converse(
            message="Night City",
            context=self._context(),
        )

        self.assertEqual(
            result.intent,
            "search",
        )

        ids = {
            item.content_id
            for item in result.items
        }

        self.assertIn(
            str(content.id),
            ids,
        )

    def test_search_never_returns_draft_content(self):
        self._content(
            title="Hidden Night",
            approved=False,
        )

        result = converse(
            message="Hidden Night",
            context=self._context(),
        )

        self.assertEqual(
            result.items,
            tuple(),
        )

    def test_help_never_creates_catalogue_items(self):
        result = converse(
            message="help",
            context=self._context(),
        )

        self.assertEqual(
            result.intent,
            "help",
        )

        self.assertEqual(
            result.items,
            tuple(),
        )

    def test_no_match_is_grounded_empty_response(self):
        result = converse(
            message="nonexistent spaceship",
            context=self._context(),
        )

        self.assertEqual(
            result.items,
            tuple(),
        )

        self.assertIn(
            "could not find",
            result.reply.lower(),
        )

    def test_response_contract(self):
        result = converse(
            message="help",
            context=self._context(),
        )

        payload = result.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_CONVERSATIONAL_VERSION,
        )

        self.assertEqual(
            payload["profile_id"],
            "chat-profile",
        )

        self.assertEqual(
            payload["item_count"],
            0,
        )

        self.assertIn(
            "intent",
            payload,
        )

        self.assertIn(
            "reply",
            payload,
        )
