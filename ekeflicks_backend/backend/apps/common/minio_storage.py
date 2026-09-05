import boto3
from botocore.config import Config
from django.conf import settings


def minio_client(endpoint_url):
    return boto3.client(
        's3',
        endpoint_url=endpoint_url,
        aws_access_key_id=settings.MINIO_ACCESS_KEY,
        aws_secret_access_key=settings.MINIO_SECRET_KEY,
        region_name=settings.MINIO_REGION,
        use_ssl=endpoint_url.startswith('https://'),
        verify=True,
        config=Config(
            signature_version='s3v4',
            s3={'addressing_style': 'path'},
        ),
    )


def minio_internal_client():
    return minio_client(
        settings.MINIO_ENDPOINT.rstrip('/')
    )


def minio_public_upload_client():
    return minio_client(
        settings.MINIO_PUBLIC_ENDPOINT.rstrip('/')
    )
