from django.test import TestCase
from django.utils import timezone

from apps.streaming.technical_conformity import (
    evaluate_master_conformity,
)
from core.models import TechnicalSpecification


class MasterTechnicalConformityTests(TestCase):
    def setUp(self):
        TechnicalSpecification.objects.create(
            title="Spec QC vidéo test",
            version="qc-master-test-1",
            introduction="",
            sections=[
                {
                    "key": "program_video",
                    "title": "Vidéo programme",
                    "items": [
                        {
                            "label": "H264 MOV",
                            "value": (
                                "Non accepté. Une source "
                                "H.264 doit être encapsulée "
                                "en MP4."
                            ),
                            "required": True,
                            "rule_key": (
                                "master.h264_container"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Framerate",
                            "value": (
                                "Constant : 23.976, 24, "
                                "25, 29.97 ou 30 fps."
                            ),
                            "required": True,
                            "rule_key": (
                                "master.allowed_fps"
                            ),
                            "auto_validation": True,
                        },
                        {
                            "label": "Scan",
                            "value": (
                                "Progressif uniquement."
                            ),
                            "required": True,
                            "rule_key": (
                                "master.progressive"
                            ),
                            "auto_validation": True,
                        },
                    ],
                }
            ],
            is_published=True,
            published_at=timezone.now(),
        )

    def _metadata(
        self,
        *,
        filename="master.mp4",
        codec="h264",
        field_order="progressive",
    ):
        return {
            "format": {
                "filename": filename,
                "format_name": (
                    "mov,mp4,m4a,3gp,3g2,mj2"
                ),
                "format_long_name": (
                    "QuickTime / MOV"
                ),
            },
            "streams": [
                {
                    "codec_type": "video",
                    "codec_name": codec,
                    "field_order": field_order,
                },
                {
                    "codec_type": "audio",
                    "codec_name": "aac",
                },
            ],
        }

    def test_valid_mp4_h264_25fps_passes(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(),
            frame_rate=25.0,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )
        self.assertFalse(
            result["blocking"]
        )

    def test_h264_mov_is_blocking(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                filename="master.mov",
            ),
            frame_rate=25.0,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

        self.assertTrue(
            any(
                item["rule_key"]
                == "master.h264_container"
                and item["status"]
                == "failed"
                for item in result["checks"]
            )
        )

    def test_invalid_fps_is_blocking(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(),
            frame_rate=60.0,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

        self.assertTrue(
            any(
                item["rule_key"]
                == "master.allowed_fps"
                and item["status"]
                == "failed"
                for item in result["checks"]
            )
        )

    def test_interlaced_is_blocking(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                field_order="tt",
            ),
            frame_rate=25.0,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

        self.assertTrue(
            any(
                item["rule_key"]
                == "master.progressive"
                and item["status"]
                == "failed"
                for item in result["checks"]
            )
        )

    def test_unknown_scan_requires_review(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                field_order="",
            ),
            frame_rate=25.0,
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
        self.assertFalse(
            result["blocking"]
        )

    def test_ffprobe_unknown_scan_requires_review(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                field_order="unknown",
            ),
            frame_rate=25.0,
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
        self.assertFalse(
            result["blocking"]
        )

        progressive_check = next(
            item
            for item in result["checks"]
            if item["rule_key"]
            == "master.progressive"
        )

        self.assertEqual(
            progressive_check["status"],
            "review",
        )
        self.assertEqual(
            progressive_check["actual"],
            "unknown",
        )

    def test_23976_is_accepted(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(),
            frame_rate=23.976,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

class VideoAssetTechnicalConformitySerializerTests(
    TestCase
):
    def test_serializer_exposes_conformity_report(self):
        from apps.streaming.serializers import (
            VideoAssetSerializer,
        )
        from core.models import (
            Content,
            MediaAnalysisReport,
            VideoAsset,
        )

        content = Content.objects.create(
            title="Serializer QC",
            type="movie",
        )

        asset = VideoAsset.objects.create(
            content=content,
            title="Master",
        )

        MediaAnalysisReport.objects.create(
            asset=asset,
            status="passed",
            technical_metadata={
                "technical_specification_conformity": {
                    "status": "conform",
                    "blocking": False,
                    "specification_version": "1.2",
                    "checks": [],
                    "blocking_errors": [],
                    "warnings": [],
                }
            },
        )

        payload = VideoAssetSerializer(
            asset
        ).data

        self.assertEqual(
            payload["analysis_status"],
            "passed",
        )

        self.assertEqual(
            payload[
                "technical_conformity"
            ]["status"],
            "conform",
        )

        self.assertFalse(
            payload[
                "technical_conformity"
            ]["blocking"]
        )
