from django.test import TestCase

from core.models import TechnicalSpecification

from apps.streaming.technical_conformity import (
    evaluate_trailer_conformity,
)


class TrailerTechnicalConformityTests(TestCase):
    def setUp(self):
        self.spec = TechnicalSpecification.objects.create(
            title="Trailer QC",
            version="test-trailer-1",
            is_published=False,
            sections=[
                {
                    "key": "trailer",
                    "title": "Trailer",
                    "items": [
                        self._rule(
                            "trailer.container.distribution",
                            "container_allowed",
                            ["mp4"],
                        ),
                        self._rule(
                            "trailer.codec.distribution",
                            "video_codec_allowed",
                            ["h264", "hevc", "h265"],
                        ),
                        self._rule(
                            "trailer.min_resolution",
                            "min_resolution",
                            {
                                "width": 1920,
                                "height": 1080,
                            },
                        ),
                        self._rule(
                            "trailer.allowed_fps",
                            "allowed_fps",
                            [
                                23.976,
                                24,
                                25,
                                29.97,
                                30,
                            ],
                        ),
                        self._rule(
                            "trailer.constant_frame_rate",
                            "constant_frame_rate",
                            True,
                        ),
                        self._rule(
                            "trailer.progressive",
                            "progressive",
                            True,
                        ),
                        self._rule(
                            "trailer.audio.required",
                            "audio_stream_required",
                            True,
                        ),
                        self._rule(
                            "trailer.audio.codec.distribution",
                            "audio_codec_allowed",
                            ["aac"],
                        ),
                        self._rule(
                            "trailer.audio.sample_rate",
                            "audio_sample_rate",
                            48000,
                        ),
                        self._rule(
                            "trailer.duration",
                            "duration_range",
                            {
                                "min_seconds": 30,
                                "max_seconds": 150,
                            },
                        ),
                    ],
                }
            ],
        )

    def _rule(
        self,
        key,
        rule_type,
        expected,
    ):
        return {
            "label": key,
            "value": key,
            "required": True,
            "rule_key": key,
            "rule_type": rule_type,
            "expected": expected,
            "severity": "blocking",
            "auto_validation": True,
            "delivery_levels": [
                "distribution",
            ],
        }

    def _metadata(
        self,
        *,
        duration=60,
        width=1920,
        height=1080,
        codec="h264",
        audio_codec="aac",
        sample_rate="48000",
        field_order="progressive",
        is_constant=True,
    ):
        return {
            "format": {
                "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
                "filename": "trailer.mp4",
                "duration": str(duration),
            },
            "streams": [
                {
                    "codec_type": "video",
                    "codec_name": codec,
                    "width": width,
                    "height": height,
                    "field_order": field_order,
                    "r_frame_rate": "25/1",
                    "avg_frame_rate": "25/1",
                    "color_space": "bt709",
                    "color_primaries": "bt709",
                    "color_transfer": "bt709",
                },
                {
                    "codec_type": "audio",
                    "codec_name": audio_codec,
                    "sample_rate": sample_rate,
                    "channels": 2,
                },
            ],
            "frame_timing_qc": {
                "available": True,
                "frame_count": 1500,
                "is_constant": is_constant,
            },
        }

    def evaluate(
        self,
        metadata=None,
        frame_rate=25.0,
    ):
        return evaluate_trailer_conformity(
            metadata=(
                metadata
                if metadata is not None
                else self._metadata()
            ),
            frame_rate=frame_rate,
            delivery_level="distribution",
            specification=self.spec,
        )

    def test_valid_distribution_trailer_passes(self):
        result = self.evaluate()

        self.assertEqual(
            result["status"],
            "conform",
        )
        self.assertFalse(
            result["blocking"]
        )

    def test_duration_below_30_blocks(self):
        result = self.evaluate(
            self._metadata(duration=29.9)
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

    def test_duration_above_150_blocks(self):
        result = self.evaluate(
            self._metadata(duration=150.1)
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_duration_boundaries_pass(self):
        for duration in (30, 150):
            with self.subTest(
                duration=duration
            ):
                result = self.evaluate(
                    self._metadata(
                        duration=duration
                    )
                )

                self.assertEqual(
                    result["status"],
                    "conform",
                )

    def test_resolution_below_fhd_blocks(self):
        result = self.evaluate(
            self._metadata(
                width=1280,
                height=720,
            )
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_vfr_blocks(self):
        result = self.evaluate(
            self._metadata(
                is_constant=False,
            )
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_interlaced_blocks(self):
        result = self.evaluate(
            self._metadata(
                field_order="tt",
            )
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_unknown_scan_requires_review(self):
        result = self.evaluate(
            self._metadata(
                field_order="unknown",
            )
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
        self.assertFalse(
            result["blocking"]
        )

    def test_missing_audio_blocks(self):
        metadata = self._metadata()

        metadata["streams"] = [
            metadata["streams"][0]
        ]

        result = self.evaluate(
            metadata
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

    def test_wrong_audio_sample_rate_blocks(self):
        result = self.evaluate(
            self._metadata(
                sample_rate="44100",
            )
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_invalid_fps_blocks(self):
        result = self.evaluate(
            frame_rate=60.0,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_only_trailer_rules_are_used(self):
        self.spec.sections.append({
            "key": "program",
            "items": [
                {
                    "label": "Master impossible",
                    "value": "Master impossible",
                    "required": True,
                    "rule_key": (
                        "master.fake.blocking"
                    ),
                    "rule_type": (
                        "video_codec_allowed"
                    ),
                    "expected": [
                        "impossible_codec"
                    ],
                    "severity": "blocking",
                    "auto_validation": True,
                    "delivery_levels": [
                        "distribution"
                    ],
                }
            ],
        })

        self.spec.save(
            update_fields=[
                "sections",
                "updated_at",
            ]
        )

        result = self.evaluate()

        self.assertEqual(
            result["status"],
            "conform",
        )

        self.assertFalse(
            any(
                str(check["rule_key"]).startswith(
                    "master."
                )
                for check in result["checks"]
            )
        )


class TrailerColorPartialMetadataTests(
    TrailerTechnicalConformityTests
):
    def setUp(self):
        super().setUp()

        self.spec.sections[0]["items"].append(
            {
                "label": "Colorimétrie SDR",
                "value": "Rec.709",
                "required": False,
                "rule_key": "trailer.color.sdr",
                "rule_type": "color_space_sdr",
                "expected": {
                    "color_space": [
                        "bt709",
                    ],
                    "color_primaries": [
                        "bt709",
                    ],
                },
                "severity": "warning",
                "auto_validation": True,
                "delivery_levels": [
                    "distribution",
                ],
            }
        )

        self.spec.save(
            update_fields=[
                "sections",
                "updated_at",
            ]
        )

    def _color_check(self, result):
        return next(
            check
            for check in result["checks"]
            if check["rule_key"]
            == "trailer.color.sdr"
        )

    def test_bt709_complete_color_metadata_passes(
        self,
    ):
        result = self.evaluate()

        check = self._color_check(result)

        self.assertEqual(
            check["status"],
            "passed",
        )

    def test_bt709_space_without_primaries_requires_review(
        self,
    ):
        metadata = self._metadata()

        video = metadata["streams"][0]
        video["color_space"] = "bt709"
        video["color_primaries"] = None
        video["color_transfer"] = None

        result = self.evaluate(metadata)

        self.assertEqual(
            result["status"],
            "review_required",
        )

        check = self._color_check(result)

        self.assertEqual(
            check["status"],
            "review",
        )

        self.assertIn(
            "incomplètes",
            check["message"],
        )

    def test_explicit_wrong_sdr_metadata_still_fails(
        self,
    ):
        metadata = self._metadata()

        video = metadata["streams"][0]
        video["color_space"] = "smpte170m"
        video["color_primaries"] = "smpte170m"
        video["color_transfer"] = "smpte170m"

        result = self.evaluate(metadata)

        check = self._color_check(result)

        self.assertEqual(
            check["status"],
            "failed",
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
