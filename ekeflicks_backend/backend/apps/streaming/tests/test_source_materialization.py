import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock

from django.test import SimpleTestCase

from apps.streaming.tasks import (
    _materialize_storage_input,
    _source_input,
)


class ChunkedSource:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(
        self,
        exc_type,
        exc,
        traceback,
    ):
        return False

    def chunks(self):
        midpoint = max(
            1,
            len(self.payload) // 2,
        )

        yield self.payload[:midpoint]
        yield self.payload[midpoint:]


class SourceMaterializationTests(
    SimpleTestCase
):
    def test_empty_path_returns_none(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = _materialize_storage_input(
                "",
                Path(tmp),
            )

        self.assertIsNone(result)

    def test_local_storage_path_is_returned_directly(
        self,
    ):
        storage = MagicMock()
        storage.path.return_value = (
            "/storage/local/trailer.mov"
        )

        with tempfile.TemporaryDirectory() as tmp:
            result = _materialize_storage_input(
                "uploads/trailer.mov",
                Path(tmp),
                storage=storage,
            )

        self.assertEqual(
            result,
            "/storage/local/trailer.mov",
        )

        storage.path.assert_called_once_with(
            "uploads/trailer.mov"
        )

        storage.open.assert_not_called()

    def test_remote_storage_is_copied_locally(
        self,
    ):
        payload = b"ekeflicks-trailer-data"

        storage = MagicMock()

        storage.path.side_effect = (
            NotImplementedError
        )

        storage.open.return_value = (
            ChunkedSource(payload)
        )

        with tempfile.TemporaryDirectory() as tmp:
            result = _materialize_storage_input(
                (
                    "uploads/producer_1/"
                    "trailer_original.mov"
                ),
                Path(tmp),
                storage=storage,
            )

            result_path = Path(result)

            self.assertTrue(
                result_path.exists()
            )

            self.assertEqual(
                result_path.name,
                "trailer_original.mov",
            )

            self.assertEqual(
                result_path.read_bytes(),
                payload,
            )

        storage.open.assert_called_once_with(
            (
                "uploads/producer_1/"
                "trailer_original.mov"
            ),
            "rb",
        )

    def test_source_input_keeps_videoasset_behavior(
        self,
    ):
        asset = SimpleNamespace(
            source_file_path="",
            source_file_url=(
                "https://example.test/master.mov"
            ),
        )

        with tempfile.TemporaryDirectory() as tmp:
            result = _source_input(
                asset,
                Path(tmp),
            )

        self.assertEqual(
            result,
            "https://example.test/master.mov",
        )

    def test_failed_remote_copy_removes_partial_file(self):
        class BrokenSource(ChunkedSource):
            def chunks(self):
                yield b"partial-video"
                raise OSError("interrupted download")

        storage = MagicMock()
        storage.path.side_effect = NotImplementedError
        storage.open.return_value = BrokenSource(b"")
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(OSError, "interrupted download"):
                _materialize_storage_input("uploads/master.mp4", Path(tmp), storage)
            self.assertFalse((Path(tmp) / "master.mp4").exists())
