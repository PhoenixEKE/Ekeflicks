from unittest.mock import Mock

from django.test import SimpleTestCase, override_settings

from apps.streaming.multipart_upload import (
    MultipartUploadError,
    SOURCE_MULTIPART_PART_SIZE,
    abort_source_multipart_upload,
    complete_source_multipart_upload,
    create_source_multipart_upload,
    multipart_part_count,
    normalize_completed_parts,
    presign_source_multipart_part,
)


@override_settings(MINIO_BUCKET='test-video-bucket')
class SourceMultipartUploadTests(SimpleTestCase):
    def test_part_count_uses_64_mib_parts(self):
        size = (SOURCE_MULTIPART_PART_SIZE * 2) + 1

        self.assertEqual(
            multipart_part_count(size),
            3,
        )

    def test_create_initializes_storage_upload(self):
        client = Mock()
        client.create_multipart_upload.return_value = {
            'UploadId': 'upload-123',
        }

        result = create_source_multipart_upload(
            client=client,
            object_key='uploads/video.mp4',
            size_bytes=4276912571,
        )

        self.assertEqual(
            result['upload_id'],
            'upload-123',
        )
        self.assertEqual(
            result['part_size'],
            SOURCE_MULTIPART_PART_SIZE,
        )
        self.assertGreater(
            result['part_count'],
            1,
        )

        client.create_multipart_upload.assert_called_once_with(
            Bucket='test-video-bucket',
            Key='uploads/video.mp4',
            ContentType='video/mp4',
        )

    def test_presign_upload_part(self):
        client = Mock()
        client.generate_presigned_url.return_value = (
            'https://upload.test/part'
        )

        url = presign_source_multipart_part(
            client=client,
            bucket='test-video-bucket',
            object_key='uploads/video.mp4',
            upload_id='upload-123',
            part_number=2,
            part_count=4,
        )

        self.assertEqual(
            url,
            'https://upload.test/part',
        )

        client.generate_presigned_url.assert_called_once_with(
            ClientMethod='upload_part',
            Params={
                'Bucket': 'test-video-bucket',
                'Key': 'uploads/video.mp4',
                'UploadId': 'upload-123',
                'PartNumber': 2,
            },
            ExpiresIn=3600,
            HttpMethod='PUT',
        )

    def test_presign_rejects_out_of_range_part(self):
        with self.assertRaises(MultipartUploadError):
            presign_source_multipart_part(
                client=Mock(),
                bucket='test-video-bucket',
                object_key='uploads/video.mp4',
                upload_id='upload-123',
                part_number=5,
                part_count=4,
            )

    def test_completed_parts_are_sorted(self):
        parts = normalize_completed_parts(
            [
                {
                    'part_number': 2,
                    'etag': '"etag-2"',
                },
                {
                    'part_number': 1,
                    'etag': '"etag-1"',
                },
            ],
            part_count=2,
        )

        self.assertEqual(
            parts,
            [
                {
                    'PartNumber': 1,
                    'ETag': '"etag-1"',
                },
                {
                    'PartNumber': 2,
                    'ETag': '"etag-2"',
                },
            ],
        )

    def test_completed_parts_require_every_part(self):
        with self.assertRaises(MultipartUploadError):
            normalize_completed_parts(
                [
                    {
                        'part_number': 1,
                        'etag': '"etag-1"',
                    },
                ],
                part_count=2,
            )

    def test_complete_calls_storage(self):
        client = Mock()

        complete_source_multipart_upload(
            client=client,
            bucket='test-video-bucket',
            object_key='uploads/video.mp4',
            upload_id='upload-123',
            parts=[
                {
                    'part_number': 1,
                    'etag': '"etag-1"',
                },
                {
                    'part_number': 2,
                    'etag': '"etag-2"',
                },
            ],
            part_count=2,
        )

        client.complete_multipart_upload.assert_called_once_with(
            Bucket='test-video-bucket',
            Key='uploads/video.mp4',
            UploadId='upload-123',
            MultipartUpload={
                'Parts': [
                    {
                        'PartNumber': 1,
                        'ETag': '"etag-1"',
                    },
                    {
                        'PartNumber': 2,
                        'ETag': '"etag-2"',
                    },
                ],
            },
        )

    def test_abort_calls_storage(self):
        client = Mock()

        abort_source_multipart_upload(
            client=client,
            bucket='test-video-bucket',
            object_key='uploads/video.mp4',
            upload_id='upload-123',
        )

        client.abort_multipart_upload.assert_called_once_with(
            Bucket='test-video-bucket',
            Key='uploads/video.mp4',
            UploadId='upload-123',
        )
