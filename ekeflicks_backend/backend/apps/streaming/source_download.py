"""Copy a storage source without an extra S3 temporary-file round trip."""

from boto3.s3.transfer import S3Transfer
from storages.backends.s3 import S3File


def copy_storage_source(source_file, destination, storage):
    """Keep Django's read semantics, optimizing the standard binary S3 reader.

    S3File.chunks() first downloads the whole object to its own spool. Send
    that same managed download straight to the caller's seekable work file.
    Custom readers and gzip-enabled storage retain their normal chunks path.
    """
    if type(source_file) is S3File and not storage.gzip:
        parameters = storage.get_object_parameters(source_file.name)
        download_parameters = {
            key: value
            for key, value in parameters.items()
            if key in S3Transfer.ALLOWED_DOWNLOAD_ARGS
        }
        source_file.obj.download_fileobj(
            destination,
            ExtraArgs=download_parameters,
            Config=storage.transfer_config,
        )
        return

    for chunk in source_file.chunks():
        destination.write(chunk)
