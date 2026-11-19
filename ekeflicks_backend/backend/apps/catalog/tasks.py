import logging
import os
from datetime import timedelta

from celery import shared_task
from django.db import transaction
from django.utils import timezone

from apps.catalog.draft_cleanup import delete_draft_temporary_media
from apps.streaming.services import delete_video_asset_sources
from core.models import Content
from apps.catalog.translations import (
    content_source,
    source_hash,
    translate_technical_texts,
    translate_texts,
)


logger = logging.getLogger(__name__)

DRAFT_RETENTION_DAYS = 120


def _provider_translate(value, target):
    """DeepL adapter; disabled cleanly until DEEPL_AUTH_KEY is configured."""
    import requests

    key = os.environ.get('DEEPL_AUTH_KEY', '').strip()
    if not key:
        return None
    endpoint = os.environ.get(
        'DEEPL_API_URL',
        'https://api-free.deepl.com/v2/translate',
    )
    response = requests.post(
        endpoint,
        headers={'Authorization': f'DeepL-Auth-Key {key}'},
        data={'text': value, 'target_lang': target.upper()},
        timeout=20,
    )
    response.raise_for_status()
    result = response.json()['translations'][0]
    return result['text'], result.get('detected_source_language', '').upper()


def _translate_display_text(value, target):
    result = _provider_translate(value, target)
    if result is None:
        return value
    translated, detected_source = result
    # Keep producer wording intact when it is already in the requested
    # language, while translating mixed-language fields independently.
    return value if detected_source == target.upper() else translated


@shared_task(bind=True, max_retries=5, default_retry_delay=60)
def translate_content_fields(self, content_id):
    content = Content.objects.filter(pk=content_id).first()
    if content is None:
        return {'status': 'missing'}
    source = content_source(content)
    revision = source_hash(source)
    updated = dict(content.translations or {})
    try:
        for language in ('en', 'fr'):
            translated = translate_texts(
                source,
                lambda text: _translate_display_text(text, language),
            )
            # Never write a source-text “translation” while provider is absent.
            if os.environ.get('DEEPL_AUTH_KEY', '').strip():
                updated[language] = {
                    'source_hash': revision,
                    'value': translated,
                }
        current = Content.objects.filter(pk=content_id).first()
        if current is None or source_hash(content_source(current)) != revision:
            return {'status': 'stale'}
        current.translations = updated
        current.save(update_fields=['translations', 'updated_at'])
        return {'status': 'translated' if updated != (content.translations or {}) else 'provider_unconfigured'}
    except Exception as exc:
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=5, default_retry_delay=60)
def translate_reference_texts(self, model_label, object_id):
    """Translate genre/specification strings after edits, source-hash guarded."""
    from core.models import Genre, TechnicalSpecification
    model = {'genre': Genre, 'technical_specification': TechnicalSpecification}.get(model_label)
    if model is None:
        return {'status': 'unsupported'}
    obj = model.objects.filter(pk=object_id).first()
    if obj is None:
        return {'status': 'missing'}
    if model_label == 'genre':
        source = {'name': obj.name, 'description': obj.description}
    else:
        source = {'title': obj.title, 'introduction': obj.introduction, 'sections': obj.sections}
    revision = source_hash(source)
    updated = dict(obj.translations or {})
    if not os.environ.get('DEEPL_AUTH_KEY', '').strip():
        return {'status': 'provider_unconfigured'}
    if all(
        isinstance(updated.get(language), dict)
        and updated[language].get('source_hash') == revision
        for language in ('en', 'fr')
    ):
        return {'status': 'translation_current'}
    try:
        for language in ('en', 'fr'):
            existing = updated.get(language)
            if isinstance(existing, dict) and existing.get('source_hash') == revision:
                continue
            updated[language] = {
                'source_hash': revision,
                'value': (
                    translate_technical_texts(
                        source,
                        lambda text: _translate_display_text(text, language),
                    )
                    if model_label == 'technical_specification'
                    else translate_texts(
                        source,
                        lambda text: _translate_display_text(text, language),
                    )
                ),
            }
        fresh = model.objects.filter(pk=object_id).first()
        if fresh is None:
            return {'status': 'missing'}
        fresh_source = (
            {'name': fresh.name, 'description': fresh.description}
            if model_label == 'genre'
            else {'title': fresh.title, 'introduction': fresh.introduction, 'sections': fresh.sections}
        )
        if source_hash(fresh_source) != revision:
            return {'status': 'stale'}
        if fresh.translations == updated:
            return {'status': 'translation_current'}
        fresh.translations = updated
        fresh.save(update_fields=['translations', 'updated_at'])
        return {'status': 'translated'}
    except Exception as exc:
        raise self.retry(exc=exc)


@shared_task
def purge_expired_producer_drafts():
    cutoff = timezone.now() - timedelta(
        days=DRAFT_RETENTION_DAYS,
    )

    candidate_ids = list(
        Content.objects.filter(
            producer_submission_status='draft',
            updated_at__lte=cutoff,
        ).values_list('id', flat=True)
    )

    deleted = 0
    skipped = 0
    storage_errors = 0

    for content_id in candidate_ids:
        with transaction.atomic():
            content = (
                Content.objects.select_for_update()
                .filter(id=content_id)
                .first()
            )

            if content is None:
                skipped += 1
                continue

            # Revalidation sous verrou :
            # une sauvegarde récente ou un changement de statut
            # protège immédiatement le contenu.
            if (
                content.producer_submission_status != 'draft'
                or content.updated_at > cutoff
            ):
                skipped += 1
                continue

            cleanup_result = delete_draft_temporary_media(
                content,
            )

            storage_errors += cleanup_result['errors']

            video_cleanup_result = (
                delete_video_asset_sources(
                    content.video_assets.all()
                )
            )

            storage_errors += (
                video_cleanup_result['errors']
            )

            content.delete()
            deleted += 1

    result = {
        'candidates': len(candidate_ids),
        'deleted': deleted,
        'skipped': skipped,
        'storage_errors': storage_errors,
        'retention_days': DRAFT_RETENTION_DAYS,
    }

    logger.info(
        'Purge automatique brouillons producteurs : %s',
        result,
    )

    return result
