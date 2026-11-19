from io import BytesIO

from django.core.files.uploadedfile import (
    SimpleUploadedFile,
)
from django.test import TestCase
from django.utils import timezone
from PIL import Image
from rest_framework import serializers

from apps.catalog.technical_media_validation import (
    validate_image_against_published_spec,
)
from core.models import TechnicalSpecification


def _image_file(
    name,
    width,
    height,
    image_format="JPEG",
    mode="RGB",
):
    output = BytesIO()

    image = Image.new(
        mode,
        (width, height),
    )

    image.save(
        output,
        format=image_format,
    )

    return SimpleUploadedFile(
        name,
        output.getvalue(),
        content_type=(
            "image/png"
            if image_format == "PNG"
            else "image/jpeg"
        ),
    )


class TechnicalImageValidationTests(TestCase):
    def setUp(self):
        self.spec = TechnicalSpecification.objects.create(
            title="Cahier technique test",
            version="image-test-1",
            introduction="",
            sections=[
                {
                    "key": "poster",
                    "title": "Poster",
                    "items": [
                        {
                            "label": "Ratio",
                            "value": "2:3 exact.",
                            "required": True,
                            "rule_key": (
                                "poster.aspect_ratio"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Résolution minimale",
                            "value": (
                                "1000 × 1500 pixels."
                            ),
                            "required": True,
                            "rule_key": (
                                "poster.min_resolution"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Poids maximal",
                            "value": "20 Mo.",
                            "required": True,
                            "rule_key": (
                                "poster.max_size_mb"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Formats",
                            "value": "PNG ou JPG/JPEG.",
                            "required": True,
                            "rule_key": (
                                "poster.formats"
                            ),
                            "auto_validation": True,
                        },
                    ],
                },
                {
                    "key": "banner",
                    "title": "Bannière",
                    "items": [
                        {
                            "label": "Ratio",
                            "value": "16:9 exact.",
                            "required": True,
                            "rule_key": (
                                "banner.aspect_ratio"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Résolution minimale",
                            "value": (
                                "1920 × 1080 pixels."
                            ),
                            "required": True,
                            "rule_key": (
                                "banner.min_resolution"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Poids maximal",
                            "value": "10 Mo.",
                            "required": True,
                            "rule_key": (
                                "banner.max_size_mb"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Formats",
                            "value": "PNG ou JPG/JPEG.",
                            "required": True,
                            "rule_key": (
                                "banner.formats"
                            ),
                            "auto_validation": True,
                        },
                    ],
                },
            ],
            is_published=True,
            published_at=timezone.now(),
        )

    def test_valid_poster_passes(self):
        result = validate_image_against_published_spec(
            _image_file(
                "poster.jpg",
                1000,
                1500,
            ),
            "poster",
        )

        self.assertTrue(result["validated"])
        self.assertEqual(result["width"], 1000)
        self.assertEqual(result["height"], 1500)
        self.assertEqual(
            result["specification_version"],
            "image-test-1",
        )

    def test_invalid_poster_ratio_is_rejected(self):
        with self.assertRaises(
            serializers.ValidationError
        ):
            validate_image_against_published_spec(
                _image_file(
                    "poster.jpg",
                    1200,
                    1500,
                ),
                "poster",
            )

    def test_small_poster_is_rejected(self):
        with self.assertRaises(
            serializers.ValidationError
        ):
            validate_image_against_published_spec(
                _image_file(
                    "poster.jpg",
                    600,
                    900,
                ),
                "poster",
            )

    def test_valid_banner_passes_for_backdrop(self):
        result = validate_image_against_published_spec(
            _image_file(
                "banner.png",
                1920,
                1080,
                image_format="PNG",
            ),
            "backdrop",
        )

        self.assertTrue(result["validated"])
        self.assertEqual(
            result["spec_key"],
            "banner",
        )

    def test_non_rgb_image_is_rejected(self):
        with self.assertRaises(
            serializers.ValidationError
        ):
            validate_image_against_published_spec(
                _image_file(
                    "poster.png",
                    1000,
                    1500,
                    image_format="PNG",
                    mode="RGBA",
                ),
                "poster",
            )

    def test_fake_image_is_rejected(self):
        fake = SimpleUploadedFile(
            "poster.jpg",
            b"not-an-image",
            content_type="image/jpeg",
        )

        with self.assertRaises(
            serializers.ValidationError
        ):
            validate_image_against_published_spec(
                fake,
                "poster",
            )
