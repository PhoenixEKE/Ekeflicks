import boto3
from django.conf import settings


def get_b2_client():
    return boto3.client(
        "s3",
        endpoint_url=settings.B2_ENDPOINT,
        aws_access_key_id=settings.B2_KEY_ID,
        aws_secret_access_key=settings.B2_APPLICATION_KEY,
        region_name=settings.B2_REGION,
        verify=getattr(settings, "AWS_S3_VERIFY", True),
    )


def generate_b2_presigned_get_url(bucket_name, object_key, expires_in=300):
    client = get_b2_client()

    return client.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": bucket_name,
            "Key": object_key,
        },
        ExpiresIn=int(expires_in),
    )
