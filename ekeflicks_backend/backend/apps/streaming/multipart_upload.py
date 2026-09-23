import math

from django.conf import settings


SOURCE_MULTIPART_PART_SIZE = 64 * 1024 * 1024
SOURCE_MULTIPART_EXPIRES_IN = 3600
SOURCE_MULTIPART_MAX_PARTS = 10000


class MultipartUploadError(ValueError):
    pass


def multipart_part_count(
    size_bytes,
    *,
    part_size=SOURCE_MULTIPART_PART_SIZE,
):
    try:
        size_bytes = int(size_bytes)
        part_size = int(part_size)
    except (TypeError, ValueError) as exc:
        raise MultipartUploadError(
            'La taille multipart est invalide.'
        ) from exc

    if size_bytes <= 0:
        raise MultipartUploadError(
            'La taille du fichier doit être supérieure à zéro.'
        )

    if part_size <= 0:
        raise MultipartUploadError(
            'La taille des parties doit être supérieure à zéro.'
        )

    part_count = math.ceil(size_bytes / part_size)

    if part_count > SOURCE_MULTIPART_MAX_PARTS:
        raise MultipartUploadError(
            'Le fichier nécessite trop de parties multipart.'
        )

    return part_count


def create_source_multipart_upload(
    *,
    client,
    object_key,
    size_bytes,
):
    bucket = settings.MINIO_BUCKET
    part_count = multipart_part_count(size_bytes)

    response = client.create_multipart_upload(
        Bucket=bucket,
        Key=object_key,
        ContentType='video/mp4',
    )

    upload_id = str(response.get('UploadId') or '').strip()

    if not upload_id:
        raise MultipartUploadError(
            'Le stockage n’a pas retourné '
            'd’identifiant multipart.'
        )

    return {
        'bucket': bucket,
        'object_key': object_key,
        'upload_id': upload_id,
        'size_bytes': int(size_bytes),
        'part_size': SOURCE_MULTIPART_PART_SIZE,
        'part_count': part_count,
        'expires_in': SOURCE_MULTIPART_EXPIRES_IN,
    }


def presign_source_multipart_part(
    *,
    client,
    bucket,
    object_key,
    upload_id,
    part_number,
    part_count,
):
    try:
        part_number = int(part_number)
        part_count = int(part_count)
    except (TypeError, ValueError) as exc:
        raise MultipartUploadError(
            'Le numéro de partie est invalide.'
        ) from exc

    if part_count <= 0:
        raise MultipartUploadError(
            'Le nombre de parties est invalide.'
        )

    if part_number < 1 or part_number > part_count:
        raise MultipartUploadError(
            'Le numéro de partie est hors limites.'
        )

    return client.generate_presigned_url(
        ClientMethod='upload_part',
        Params={
            'Bucket': bucket,
            'Key': object_key,
            'UploadId': upload_id,
            'PartNumber': part_number,
        },
        ExpiresIn=SOURCE_MULTIPART_EXPIRES_IN,
        HttpMethod='PUT',
    )


def normalize_completed_parts(parts, *, part_count):
    if not isinstance(parts, list) or not parts:
        raise MultipartUploadError(
            'La liste des parties envoyées est obligatoire.'
        )

    normalized = []
    seen = set()

    for raw_part in parts:
        if not isinstance(raw_part, dict):
            raise MultipartUploadError(
                'Une partie multipart est invalide.'
            )

        try:
            part_number = int(raw_part.get('part_number'))
        except (TypeError, ValueError) as exc:
            raise MultipartUploadError(
                'Le numéro de partie est invalide.'
            ) from exc

        etag = str(raw_part.get('etag') or '').strip()

        if (
            part_number < 1
            or part_number > int(part_count)
            or part_number in seen
        ):
            raise MultipartUploadError(
                'La liste des parties multipart est incohérente.'
            )

        if not etag:
            raise MultipartUploadError(
                'L’ETag d’une partie multipart est obligatoire.'
            )

        seen.add(part_number)

        normalized.append({
            'PartNumber': part_number,
            'ETag': etag,
        })

    if len(normalized) != int(part_count):
        raise MultipartUploadError(
            'Toutes les parties multipart '
            'doivent être présentes.'
        )

    normalized.sort(
        key=lambda part: part['PartNumber']
    )

    expected = list(range(1, int(part_count) + 1))
    actual = [
        part['PartNumber']
        for part in normalized
    ]

    if actual != expected:
        raise MultipartUploadError(
            'La séquence des parties multipart '
            'est incomplète.'
        )

    return normalized


def complete_source_multipart_upload(
    *,
    client,
    bucket,
    object_key,
    upload_id,
    parts,
    part_count,
):
    normalized = normalize_completed_parts(
        parts,
        part_count=part_count,
    )

    return client.complete_multipart_upload(
        Bucket=bucket,
        Key=object_key,
        UploadId=upload_id,
        MultipartUpload={
            'Parts': normalized,
        },
    )


def abort_source_multipart_upload(
    *,
    client,
    bucket,
    object_key,
    upload_id,
):
    return client.abort_multipart_upload(
        Bucket=bucket,
        Key=object_key,
        UploadId=upload_id,
    )
