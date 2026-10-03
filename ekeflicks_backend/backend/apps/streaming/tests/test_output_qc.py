from pathlib import Path
from tempfile import TemporaryDirectory

from django.test import SimpleTestCase

from apps.streaming.tasks import _run_output_qc


class OutputQualityControlTests(SimpleTestCase):
    def _fixture(self, root):
        hls = Path(root) / 'hls'
        variant = hls / '720p'
        variant.mkdir(parents=True)
        (hls / 'master.m3u8').write_text(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000000\n720p/index.m3u8\n',
            encoding='utf-8',
        )
        (variant / 'index.m3u8').write_text(
            '#EXTM3U\n#EXTINF:5.0,\nsegment_00001.ts\n#EXT-X-ENDLIST\n',
            encoding='utf-8',
        )
        (variant / 'segment_00001.ts').write_bytes(b'test-segment')
        dash = Path(root) / 'dash'
        dash.mkdir()
        manifest = dash / 'manifest.mpd'
        manifest.write_text(
            '<MPD><Period><AdaptationSet contentType="video"><Representation id="0" /></AdaptationSet></Period></MPD>',
            encoding='utf-8',
        )
        return hls, manifest

    def test_validates_hls_segments_duration_and_dash_representations(self):
        with TemporaryDirectory() as tmp:
            hls, manifest = self._fixture(tmp)
            result = _run_output_qc(
                hls, manifest, [{'quality': '720p'}], expected_duration=5,
            )
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(result['hls_renditions'][0]['segments'], 1)
        self.assertEqual(result['dash_representations'], 1)

    def test_rejects_missing_hls_segment(self):
        with TemporaryDirectory() as tmp:
            hls, manifest = self._fixture(tmp)
            (hls / '720p' / 'segment_00001.ts').unlink()
            with self.assertRaisesMessage(ValueError, 'missing or empty segment'):
                _run_output_qc(
                    hls, manifest, [{'quality': '720p'}], expected_duration=5,
                )

    def test_rejects_short_hls_output(self):
        with TemporaryDirectory() as tmp:
            hls, manifest = self._fixture(tmp)
            with self.assertRaisesMessage(ValueError, 'shorter than the source'):
                _run_output_qc(
                    hls, manifest, [{'quality': '720p'}], expected_duration=10,
                )

    def test_rejects_dash_missing_a_rendition(self):
        with TemporaryDirectory() as tmp:
            hls, manifest = self._fixture(tmp)
            with (hls / 'master.m3u8').open('a', encoding='utf-8') as master:
                master.write('#EXT-X-STREAM-INF:BANDWIDTH=2000000\n1080p/index.m3u8\n')
            second = hls / '1080p'
            second.mkdir()
            (second / 'index.m3u8').write_text(
                '#EXTM3U\n#EXTINF:5.0,\nsegment_00001.ts\n#EXT-X-ENDLIST\n',
                encoding='utf-8',
            )
            (second / 'segment_00001.ts').write_bytes(b'test-segment')
            with self.assertRaisesMessage(ValueError, 'missing one or more video representations'):
                _run_output_qc(
                    hls, manifest, [{'quality': '720p'}, {'quality': '1080p'}],
                    expected_duration=5,
                )
