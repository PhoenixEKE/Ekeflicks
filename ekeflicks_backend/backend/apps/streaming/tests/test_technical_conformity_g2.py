from types import SimpleNamespace

from django.test import SimpleTestCase

from apps.streaming.technical_conformity import (
    evaluate_master_conformity,
)


class TechnicalConformityG2Tests(
    SimpleTestCase
):
    def _spec(
        self,
        *,
        channels=None,
        pcm_bits=None,
        level="premium",
    ):
        items = []

        if channels is not None:
            items.append({
                "label": "Canaux audio",
                "value": "Stéréo, 5.1 ou 7.1.",
                "required": True,
                "rule_key": (
                    "master.audio.channels"
                ),
                "auto_validation": True,
                "delivery_levels": [level],
                "rule_type": (
                    "audio_channels_allowed"
                ),
                "expected": channels,
                "severity": "blocking",
            })

        if pcm_bits is not None:
            items.append({
                "label": "PCM profondeur",
                "value": (
                    f"PCM {pcm_bits} bits."
                ),
                "required": True,
                "rule_key": (
                    "master.audio.pcm_bit_depth"
                ),
                "auto_validation": True,
                "delivery_levels": [level],
                "rule_type": (
                    "audio_pcm_bit_depth"
                ),
                "expected": pcm_bits,
                "severity": "blocking",
            })

        return SimpleNamespace(
            id="g2-test",
            version="g2-test",
            sections=[
                {
                    "key": "program_video",
                    "items": items,
                }
            ],
        )

    def _metadata(
        self,
        *,
        codec="pcm_s24le",
        channels=2,
        layout="stereo",
        sample_fmt="s32",
        bits_per_sample=0,
        bits_per_raw_sample=None,
    ):
        return {
            "format": {
                "format_name": "mov",
                "filename": "master.mov",
            },
            "streams": [
                {
                    "codec_type": "video",
                    "codec_name": "prores",
                },
                {
                    "codec_type": "audio",
                    "codec_name": codec,
                    "sample_rate": "48000",
                    "channels": channels,
                    "channel_layout": layout,
                    "sample_fmt": sample_fmt,
                    "bits_per_sample": (
                        bits_per_sample
                    ),
                    "bits_per_raw_sample": (
                        bits_per_raw_sample
                    ),
                },
            ],
        }

    def _check(
        self,
        result,
        key,
    ):
        return next(
            check
            for check in result["checks"]
            if check["rule_key"] == key
        )

    def test_stereo_is_accepted(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                channels=2,
                layout="stereo",
            ),
            delivery_level="premium",
            specification=self._spec(
                channels=[2, 6, 8],
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_5_1_is_accepted(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                channels=6,
                layout="5.1",
            ),
            delivery_level="premium",
            specification=self._spec(
                channels=[2, 6, 8],
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_7_1_is_accepted(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                channels=8,
                layout="7.1",
            ),
            delivery_level="premium",
            specification=self._spec(
                channels=[2, 6, 8],
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_mono_is_rejected(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                channels=1,
                layout="mono",
            ),
            delivery_level="premium",
            specification=self._spec(
                channels=[2, 6, 8],
            ),
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

    def test_pcm_s24_codec_fallback_is_24_bit(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                codec="pcm_s24le",
                sample_fmt="s32",
                bits_per_sample=0,
                bits_per_raw_sample=None,
            ),
            delivery_level="premium",
            specification=self._spec(
                pcm_bits=24,
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

        check = self._check(
            result,
            "master.audio.pcm_bit_depth",
        )

        self.assertEqual(
            check["actual"]["bits"],
            24,
        )

    def test_pcm_s16_is_rejected(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                codec="pcm_s16le",
                sample_fmt="s16",
                bits_per_sample=16,
            ),
            delivery_level="standard",
            specification=self._spec(
                pcm_bits=24,
                level="standard",
            ),
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

    def test_explicit_24_bits_wins(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                codec="pcm_s24le",
                sample_fmt="s32",
                bits_per_sample=24,
            ),
            delivery_level="standard",
            specification=self._spec(
                pcm_bits=24,
                level="standard",
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )

    def test_aac_does_not_satisfy_pcm_rule(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                codec="aac",
                sample_fmt="fltp",
                bits_per_sample=0,
            ),
            delivery_level="premium",
            specification=self._spec(
                pcm_bits=24,
            ),
        )

        self.assertEqual(
            result["status"],
            "non_conform",
        )
        self.assertTrue(
            result["blocking"]
        )

    def test_channels_and_pcm_can_pass_together(self):
        result = evaluate_master_conformity(
            metadata=self._metadata(
                codec="pcm_s24le",
                channels=6,
                layout="5.1",
                sample_fmt="s32",
            ),
            delivery_level="premium",
            specification=self._spec(
                channels=[2, 6, 8],
                pcm_bits=24,
            ),
        )

        self.assertEqual(
            result["status"],
            "conform",
        )
        self.assertFalse(
            result["blocking"]
        )

        self.assertEqual(
            len(result["checks"]),
            2,
        )
