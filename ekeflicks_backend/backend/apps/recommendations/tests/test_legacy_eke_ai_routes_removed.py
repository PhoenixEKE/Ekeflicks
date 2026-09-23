from django.test import SimpleTestCase
from django.urls import (
    Resolver404,
    resolve,
)


class LegacyRecommendationAPIRemovedTests(
    SimpleTestCase
):
    def test_recommendations_api_surface_is_removed(self):
        paths = (
            "/api/v1/recommendations/",
            "/api/v1/recommendations/1/",
            "/api/v1/recommendations/engine-status/",
            "/api/v1/recommendations/sync-graph/",
            "/api/v1/recommendations/generate/",
            "/api/v1/recommendations/1/mark-viewed/",
            "/api/v1/recommendations/eke-ai-status/",
            "/api/v1/recommendations/intelligent-search/",
            "/api/v1/recommendations/eke-ai-chat/",
            "/api/v1/recommendations/explain-recommendation/",
            "/api/v1/recommendations/eke-ai-feedback/",
        )

        for path in paths:
            with self.subTest(
                path=path
            ):
                with self.assertRaises(
                    Resolver404
                ):
                    resolve(
                        path
                    )

    def test_public_eke_ai_routes_exist(self):
        public = {
            "/api/v1/eke-ai/status/":
                "eke-ai-status",

            "/api/v1/eke-ai/for-you/":
                "eke-ai-for-you",

            "/api/v1/eke-ai/search/":
                "eke-ai-search",

            "/api/v1/eke-ai/chat/":
                "eke-ai-chat",

            "/api/v1/eke-ai/explain/":
                "eke-ai-explain",

            "/api/v1/eke-ai/feedback/":
                "eke-ai-feedback",
        }

        for path, name in public.items():
            with self.subTest(
                path=path
            ):
                self.assertEqual(
                    resolve(path).url_name,
                    name,
                )
