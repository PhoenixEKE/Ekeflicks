from django.test import TestCase

from apps.catalog.serializers import ContentDetailSerializer
from core.models import Content


class ContentMetadataLanguageTests(TestCase):
    def test_audio_and_subtitle_languages_default_to_empty_lists(self):
        content = Content.objects.create(
            title="Metadata defaults",
            type="movie",
        )

        self.assertEqual(
            content.audio_languages,
            [],
        )
        self.assertEqual(
            content.subtitle_languages,
            [],
        )

    def test_serializer_can_store_audio_and_subtitle_languages(self):
        content = Content.objects.create(
            title="Metadata update",
            type="movie",
        )

        serializer = ContentDetailSerializer(
            content,
            data={
                "audio_languages": [
                    "Français",
                    "Anglais",
                ],
                "subtitle_languages": [
                    "Français",
                    "Espagnol",
                ],
            },
            partial=True,
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        serializer.save()

        content.refresh_from_db()

        self.assertEqual(
            content.audio_languages,
            [
                "Français",
                "Anglais",
            ],
        )
        self.assertEqual(
            content.subtitle_languages,
            [
                "Français",
                "Espagnol",
            ],
        )

    def test_serializer_accepts_empty_subtitle_languages(self):
        content = Content.objects.create(
            title="No subtitles",
            type="movie",
            subtitle_languages=["Français"],
        )

        serializer = ContentDetailSerializer(
            content,
            data={
                "subtitle_languages": [],
            },
            partial=True,
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        serializer.save()

        content.refresh_from_db()

        self.assertEqual(
            content.subtitle_languages,
            [],
        )

    def test_serializer_rejects_non_string_language_items(self):
        content = Content.objects.create(
            title="Invalid languages",
            type="movie",
        )

        serializer = ContentDetailSerializer(
            content,
            data={
                "audio_languages": [
                    "Français",
                    {
                        "language": "Anglais",
                    },
                ],
            },
            partial=True,
        )

        self.assertFalse(
            serializer.is_valid()
        )
        self.assertIn(
            "audio_languages",
            serializer.errors,
        )

    def test_serializer_exposes_language_metadata(self):
        content = Content.objects.create(
            title="Metadata representation",
            type="movie",
            language="Français",
            country="Côte d'Ivoire",
            audio_languages=[
                "Français",
                "Anglais",
            ],
            subtitle_languages=[
                "Français",
            ],
        )

        data = ContentDetailSerializer(
            content
        ).data

        self.assertEqual(
            data["language"],
            "Français",
        )
        self.assertEqual(
            data["country"],
            "Côte d'Ivoire",
        )
        self.assertEqual(
            data["audio_languages"],
            [
                "Français",
                "Anglais",
            ],
        )
        self.assertEqual(
            data["subtitle_languages"],
            [
                "Français",
            ],
        )
