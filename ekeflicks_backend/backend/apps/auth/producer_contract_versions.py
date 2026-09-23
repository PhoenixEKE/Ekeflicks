from __future__ import annotations

import hashlib

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from core.models.producers import ProducerContractVersion


class ProducerContractVersionError(Exception):
    pass


def normalize_contract_content(value: str) -> str:
    """
    Canonical textual representation used for SHA-256.

    We normalize only line endings. Contract wording itself is never
    rewritten, trimmed or otherwise transformed.
    """
    if value is None:
        return ""

    return str(value).replace("\r\n", "\n").replace("\r", "\n")


def contract_content_sha256(value: str) -> str:
    content = normalize_contract_content(value)

    return hashlib.sha256(
        content.encode("utf-8")
    ).hexdigest()


def get_published_contract_version():
    return (
        ProducerContractVersion.objects
        .filter(
            status=ProducerContractVersion.STATUS_PUBLISHED,
        )
        .order_by(
            "-published_at",
            "-created_at",
        )
        .first()
    )


def get_current_contract_version() -> str:
    """
    DB published version is authoritative.

    Settings remain a temporary compatibility fallback while no DB
    contract has yet been published.
    """
    published = get_published_contract_version()

    if published is not None:
        return published.version

    return settings.PRODUCER_AGREEMENT_CURRENT_VERSION


def get_current_contract_title() -> str:
    published = get_published_contract_version()

    if published is not None:
        return published.title

    return settings.PRODUCER_AGREEMENT_TITLE


def current_contract_requires_reacceptance() -> bool:
    published = get_published_contract_version()

    if published is None:
        return False

    return published.requires_reacceptance


def get_recognized_signed_versions():
    """
    Versions whose existing signatures can currently be recognized.

    Before the DB contract system is published, preserve the historical
    settings behavior exactly.

    If the published DB version requires reacceptance, only that version
    satisfies the current contractual requirement. Historical agreements
    remain stored and downloadable but no longer satisfy current access.

    If reacceptance is not required, legacy accepted versions remain
    recognized alongside the DB-published version.
    """
    published = get_published_contract_version()

    if published is None:
        return tuple(
            settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS
        )

    if published.requires_reacceptance:
        return (published.version,)

    legacy = tuple(
        settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS
    )

    return tuple(
        dict.fromkeys(
            (
                published.version,
                *legacy,
            )
        )
    )


@transaction.atomic
def publish_contract_version(instance):
    """
    Publish one contract version atomically.

    A published version is a legal reference and must not be edited
    in place. Publishing another version archives the previous one.
    """
    instance = (
        ProducerContractVersion.objects
        .select_for_update()
        .get(pk=instance.pk)
    )

    if instance.status == ProducerContractVersion.STATUS_PUBLISHED:
        raise ProducerContractVersionError(
            "Cette version est deja publiee."
        )

    content = normalize_contract_content(
        instance.canonical_content
    )

    if not content.strip():
        raise ProducerContractVersionError(
            "Le contenu contractuel canonique est obligatoire."
        )

    if not instance.version.strip():
        raise ProducerContractVersionError(
            "La version contractuelle est obligatoire."
        )

    if not instance.title.strip():
        raise ProducerContractVersionError(
            "Le titre contractuel est obligatoire."
        )

    now = timezone.now()

    (
        ProducerContractVersion.objects
        .select_for_update()
        .filter(
            status=ProducerContractVersion.STATUS_PUBLISHED,
        )
        .exclude(pk=instance.pk)
        .update(
            status=ProducerContractVersion.STATUS_ARCHIVED,
            archived_at=now,
        )
    )

    instance.canonical_content = content
    instance.content_sha256 = contract_content_sha256(content)
    instance.status = ProducerContractVersion.STATUS_PUBLISHED
    instance.published_at = now
    instance.archived_at = None

    if instance.effective_date is None:
        instance.effective_date = timezone.localdate(now)

    instance.save(
        update_fields=[
            "canonical_content",
            "content_sha256",
            "status",
            "published_at",
            "archived_at",
            "effective_date",
            "updated_at",
        ]
    )

    return instance
