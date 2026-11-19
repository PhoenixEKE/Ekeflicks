from celery import shared_task
import os
import requests
from django.db import transaction

from apps.auth.services import process_due_account_closure_requests
from apps.auth.producer_contract_versions import contract_content_sha256
from core.models import ProducerContractVersion


@shared_task(bind=True, max_retries=5, default_retry_delay=60)
def translate_contract_version(self, version_id):
    """Prepare bilingual draft text. Published/signed versions stay immutable."""
    version = ProducerContractVersion.objects.filter(pk=version_id).first()
    if version is None or version.status not in {
        ProducerContractVersion.STATUS_DRAFT,
        ProducerContractVersion.STATUS_PUBLISHED,
    }:
        return {'status': 'not_translatable'}
    key = os.environ.get('DEEPL_AUTH_KEY', '').strip()
    if not key:
        return {'status': 'provider_unconfigured'}
    endpoint = os.environ.get('DEEPL_API_URL', 'https://api-free.deepl.com/v2/translate')
    content = version.canonical_content.replace('\r\n', '\n').replace('\r', '\n')
    revision = contract_content_sha256(content)
    title_revision = contract_content_sha256(version.title)
    current = dict(version.canonical_content_translations or {})
    try:
        current['fr'] = {
            'source_hash': revision,
            'value': content,
            'title_source_hash': title_revision,
            'title': version.title,
            'reviewed': True,
        }
        for target in ('EN',):
            existing = current.get(target.lower())
            if (
                isinstance(existing, dict)
                and existing.get('source_hash') == revision
                and existing.get('title_source_hash') == title_revision
            ):
                continue
            def translate(value):
                response = requests.post(
                    endpoint,
                    headers={'Authorization': f'DeepL-Auth-Key {key}'},
                    data={'text': value, 'target_lang': target},
                    timeout=30,
                )
                response.raise_for_status()
                return response.json()['translations'][0]['text']

            current[target.lower()] = {
                'source_hash': revision,
                'value': translate(content),
                'title_source_hash': title_revision,
                'title': translate(version.title),
                'reviewed': False,
            }
        if current == (version.canonical_content_translations or {}):
            return {'status': 'translation_current'}
        with transaction.atomic():
            locked = ProducerContractVersion.objects.select_for_update().get(pk=version_id)
            if (
                locked.status not in {
                    ProducerContractVersion.STATUS_DRAFT,
                    ProducerContractVersion.STATUS_PUBLISHED,
                }
                or contract_content_sha256(locked.canonical_content) != revision
                or contract_content_sha256(locked.title) != title_revision
            ):
                return {'status': 'stale'}
            locked.canonical_content_translations = current
            locked.save(update_fields=['canonical_content_translations', 'updated_at'])
        return {'status': 'translated_review_required'}
    except Exception as exc:
        raise self.retry(exc=exc)


@shared_task
def process_due_account_closures():
    return process_due_account_closure_requests()
