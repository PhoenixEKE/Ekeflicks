import gzip
import io
from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import MagicMock, patch

from boto3.s3.transfer import TransferConfig
from storages.backends.s3 import S3File

from apps.streaming.source_download import copy_storage_source


class SourceDownloadTests(TestCase):
    def make_source(self, payload=b"video-source", *, compressed=False):
        storage = MagicMock()
        storage.location = "private"
        storage.gzip = compressed
        storage.max_memory_size = 1024
        storage.transfer_config = TransferConfig(max_concurrency=3)
        storage.get_object_parameters.return_value = {
            "RequestPayer": "requester",
            "SSECustomerAlgorithm": "AES256",
            "ContentType": "video/mp4",
        }
        source = S3File("private/uploads/master.mp4", "rb", storage,
                        buffer_size=5242880)
        source.obj.content_encoding = "gzip" if compressed else None
        source.obj.download_fileobj.side_effect = (
            lambda destination, **kwargs: destination.write(payload)
        )
        return source, storage

    def test_s3_download_bypasses_spool_and_preserves_parameters(self):
        payload = b"video-source" * 1024
        source, storage = self.make_source(payload)
        destination = io.BytesIO()
        with source, patch.object(S3File, "chunks", side_effect=AssertionError):
            copy_storage_source(source, destination, storage)
            self.assertIsNone(source._file)
        self.assertEqual(destination.getvalue(), payload)
        source.obj.download_fileobj.assert_called_once_with(
            destination,
            ExtraArgs={"RequestPayer": "requester", "SSECustomerAlgorithm": "AES256"},
            Config=storage.transfer_config,
        )
        storage.bucket.Object.assert_called_once_with("private/uploads/master.mp4")
        storage.get_object_parameters.assert_called_with("uploads/master.mp4")

    def test_generic_reader_keeps_chunked_copy(self):
        source = SimpleNamespace(chunks=lambda: iter([b"first", b"second"]))
        destination = io.BytesIO()
        copy_storage_source(source, destination, object())
        self.assertEqual(destination.getvalue(), b"firstsecond")

    def test_gzip_storage_preserves_decompression(self):
        payload = b"decoded-video" * 100
        source, storage = self.make_source(gzip.compress(payload), compressed=True)
        destination = io.BytesIO()
        with source:
            copy_storage_source(source, destination, storage)
        self.assertEqual(destination.getvalue(), payload)

    def test_custom_s3_reader_preserves_overridden_chunks(self):
        class CustomReader(S3File):
            def chunks(self):
                yield b"custom-decoded-video"
        source, storage = self.make_source()
        source.__class__ = CustomReader
        destination = io.BytesIO()
        with source:
            copy_storage_source(source, destination, storage)
        self.assertEqual(destination.getvalue(), b"custom-decoded-video")
        source.obj.download_fileobj.assert_not_called()

    def test_transfer_error_is_not_retried_as_a_second_full_download(self):
        source, storage = self.make_source()
        source.obj.download_fileobj.side_effect = OSError("transfer failed")
        with source, self.assertRaisesRegex(OSError, "transfer failed"):
            copy_storage_source(source, io.BytesIO(), storage)
        source.obj.download_fileobj.assert_called_once()

    def test_empty_s3_object_is_copied(self):
        source, storage = self.make_source(b"")
        destination = io.BytesIO()
        with source:
            copy_storage_source(source, destination, storage)
        self.assertEqual(destination.getvalue(), b"")
