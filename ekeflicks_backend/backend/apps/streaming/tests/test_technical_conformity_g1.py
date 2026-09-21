from django.test import TestCase

from apps.streaming.technical_conformity import (
    evaluate_master_conformity,
)
from core.models import TechnicalSpecification


class TechnicalConformityG1Tests(TestCase):
    def _spec(self, *, level, profiles=None):
        items = [
            {
                "label": "Audio obligatoire",
                "value": "Une piste audio est obligatoire.",
                "required": True,
                "rule_key": "master.audio.required",
                "auto_validation": True,
                "delivery_levels": [
                    "premium",
                    "standard",
                    "distribution",
                ],
                "rule_type": "audio_stream_required",
                "expected": True,
                "severity": "blocking",
            },
        ]

        if profiles is not None:
            items.append(
                {
                    "label": "Profil ProRes",
                    "value": "Profil ProRes exact.",
                    "required": True,
                    "rule_key": (
                        f"master.prores_profile.{level}"
                    ),
                    "auto_validation": True,
                    "delivery_levels": [level],
                    "rule_type": "prores_profile_allowed",
                    "expected": profiles,
                    "severity": "blocking",
                }
            )

        return TechnicalSpecification.objects.create(
            title="Spec A5.11G-1 test",
            version=(
                f"g1-{level}-{self._testMethodName}"
            )[:50],
            introduction="",
            sections=[
                {
                    "key": "program_video",
                    "title": "Vidéo programme",
                    "items": items,
                }
            ],
            is_published=False,
        )

    def _metadata(
        self,
        *,
        profile="HQ",
        tag="apch",
        audio=True,
    ):
        streams = [
            {
                "codec_type": "video",
                "codec_name": "prores",
                "profile": profile,
                "codec_tag_string": tag,
            }
        ]

        if audio:
            streams.append(
                {
                    "codec_type": "audio",
                    "codec_name": "pcm_s24le",
                    "sample_rate": "48000",
                    "channels": 2,
                }
            )

        return {
            "format": {
                "format_name": "mov",
                "filename": "master.mov",
            },
            "streams": streams,
        }

    def _check(self, result, rule_key):
        return next(
            check
            for check in result["checks"]
            if check["rule_key"] == rule_key
        )

    def test_premium_accepts_prores_hq(self):
        spec = self._spec(
            level="premium",
            profiles=["hq", "4444", "xq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="HQ",
                tag="apch",
            ),
            delivery_level="premium",
            specification=spec,
        )

        self.assertEqual(result["status"], "conform")

        check = self._check(
            result,
            "master.prores_profile.premium",
        )

        self.assertEqual(check["status"], "passed")
        self.assertEqual(check["actual"], "hq")

    def test_premium_accepts_4444_xq(self):
        spec = self._spec(
            level="premium",
            profiles=["hq", "4444", "xq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="XQ",
                tag="ap4x",
            ),
            delivery_level="premium",
            specification=spec,
        )

        self.assertEqual(result["status"], "conform")

        check = self._check(
            result,
            "master.prores_profile.premium",
        )

        self.assertEqual(check["actual"], "xq")

    def test_premium_rejects_standard_422(self):
        spec = self._spec(
            level="premium",
            profiles=["hq", "4444", "xq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="Standard",
                tag="apcn",
            ),
            delivery_level="premium",
            specification=spec,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(result["blocking"])

    def test_standard_accepts_standard_422(self):
        spec = self._spec(
            level="standard",
            profiles=["standard", "hq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="Standard",
                tag="apcn",
            ),
            delivery_level="standard",
            specification=spec,
        )

        self.assertEqual(result["status"], "conform")

    def test_standard_accepts_hq(self):
        spec = self._spec(
            level="standard",
            profiles=["standard", "hq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="HQ",
                tag="apch",
            ),
            delivery_level="standard",
            specification=spec,
        )

        self.assertEqual(result["status"], "conform")

    def test_standard_rejects_4444(self):
        spec = self._spec(
            level="standard",
            profiles=["standard", "hq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="4444",
                tag="ap4h",
            ),
            delivery_level="standard",
            specification=spec,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

    def test_fourcc_fallback_detects_hq(self):
        spec = self._spec(
            level="premium",
            profiles=["hq", "4444", "xq"],
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                profile="",
                tag="apch",
            ),
            delivery_level="premium",
            specification=spec,
        )

        check = self._check(
            result,
            "master.prores_profile.premium",
        )

        self.assertEqual(check["actual"], "hq")
        self.assertEqual(check["status"], "passed")

    def test_missing_audio_is_blocking(self):
        spec = self._spec(
            level="distribution",
            profiles=None,
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                audio=False,
            ),
            delivery_level="distribution",
            specification=spec,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(result["blocking"])

        check = self._check(
            result,
            "master.audio.required",
        )

        self.assertEqual(check["status"], "failed")
        self.assertFalse(check["actual"])

    def test_audio_present_passes_required_rule(self):
        spec = self._spec(
            level="distribution",
            profiles=None,
        )

        result = evaluate_master_conformity(
            metadata=self._metadata(
                audio=True,
            ),
            delivery_level="distribution",
            specification=spec,
        )

        self.assertEqual(result["status"], "conform")

        check = self._check(
            result,
            "master.audio.required",
        )

        self.assertEqual(check["status"], "passed")
        self.assertTrue(check["actual"])
