from types import SimpleNamespace

from django.test import SimpleTestCase

from apps.streaming.technical_conformity import (
    evaluate_master_conformity,
)


class ResolutionAllowedProfilesTests(
    SimpleTestCase
):
    def _spec(self):
        return SimpleNamespace(
            id="g3-resolution",
            version="g3-resolution",
            sections=[
                {
                    "key": "program_video",
                    "items": [
                        {
                            "label": (
                                "Profils résolution "
                                "Master Premium"
                            ),
                            "value": (
                                "UHD / DCI / cinéma."
                            ),
                            "required": True,
                            "rule_key": (
                                "master.resolution."
                                "premium"
                            ),
                            "auto_validation": True,
                            "delivery_levels": [
                                "premium",
                            ],
                            "rule_type": (
                                "resolution_"
                                "allowed_profiles"
                            ),
                            "expected": [
                                {
                                    "width": 3840,
                                    "height": 2160,
                                    "label": "UHD 4K",
                                },
                                {
                                    "width": 4096,
                                    "height": 2160,
                                    "label": "DCI 4K Full",
                                },
                                {
                                    "width": 3996,
                                    "height": 2160,
                                    "label": "DCI 4K Flat",
                                },
                                {
                                    "width": 4096,
                                    "height": 1716,
                                    "label": "DCI 4K Scope",
                                },
                                {
                                    "width": 3840,
                                    "height": 1608,
                                    "label": "UHD Scope",
                                },
                            ],
                            "severity": "blocking",
                        }
                    ],
                }
            ],
        )

    def _evaluate(
        self,
        width,
        height,
    ):
        return evaluate_master_conformity(
            metadata={
                "format": {
                    "format_name": "mov",
                    "filename": "master.mov",
                },
                "streams": [
                    {
                        "codec_type": "video",
                        "codec_name": "prores",
                        "profile": "HQ",
                        "codec_tag_string": "apch",
                        "width": width,
                        "height": height,
                        "field_order": "progressive",
                    },
                    {
                        "codec_type": "audio",
                        "codec_name": "pcm_s24le",
                        "sample_rate": "48000",
                        "channels": 2,
                    },
                ],
            },
            delivery_level="premium",
            specification=self._spec(),
        )

    def _resolution_check(
        self,
        result,
    ):
        return next(
            item
            for item in result["checks"]
            if item["rule_key"]
            == "master.resolution.premium"
        )

    def test_uhd_is_accepted(self):
        result = self._evaluate(
            3840,
            2160,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

        self.assertEqual(
            self._resolution_check(
                result
            )["status"],
            "passed",
        )

    def test_dci_full_is_accepted(self):
        result = self._evaluate(
            4096,
            2160,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_dci_flat_is_accepted(self):
        result = self._evaluate(
            3996,
            2160,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_dci_scope_is_accepted(self):
        result = self._evaluate(
            4096,
            1716,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_uhd_scope_is_accepted(self):
        result = self._evaluate(
            3840,
            1608,
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_full_hd_is_rejected_for_premium(self):
        result = self._evaluate(
            1920,
            1080,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

        self.assertTrue(
            result["blocking"]
        )

        self.assertEqual(
            self._resolution_check(
                result
            )["status"],
            "failed",
        )

    def test_2k_is_rejected_for_premium(self):
        result = self._evaluate(
            2048,
            1080,
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )

        self.assertTrue(
            result["blocking"]
        )

    def test_non_list_rule_requires_review(self):
        spec = self._spec()

        spec.sections[0]["items"][0][
            "expected"
        ] = {
            "width": 3840,
            "height": 2160,
        }

        result = evaluate_master_conformity(
            metadata={
                "format": {
                    "format_name": "mov",
                },
                "streams": [
                    {
                        "codec_type": "video",
                        "codec_name": "prores",
                        "width": 3840,
                        "height": 2160,
                    }
                ],
            },
            delivery_level="premium",
            specification=spec,
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )

    def test_missing_resolution_requires_review(self):
        result = evaluate_master_conformity(
            metadata={
                "format": {
                    "format_name": "mov",
                },
                "streams": [
                    {
                        "codec_type": "video",
                        "codec_name": "prores",
                    }
                ],
            },
            delivery_level="premium",
            specification=self._spec(),
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
