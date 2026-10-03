import base64
import hashlib
import hmac
import json

import jwt
import uuid
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.core.files.storage import default_storage
from django.utils import timezone

from apps.streaming.storage_paths import build_source_upload_path
from core.models import PlaybackLicense, Profile, Subscription


def get_profile_for_user(user, profile_id=None):
    queryset = Profile.objects.filter(user=user, is_active=True).select_related('type')
    if profile_id:
        return queryset.get(pk=profile_id)
    return queryset.order_by('created_at').first()


def get_active_subscription(user):
    return (
        Subscription.objects.filter(
            user=user,
            status='active',
            expires_at__gt=timezone.now(),
        )
        .select_related('plan')
        .order_by('-expires_at')
        .first()
    )


def streaming_subscription_required():
    return getattr(settings, 'STREAMING_REQUIRE_ACTIVE_SUBSCRIPTION', True)


def offline_license_days():
    return getattr(settings, 'OFFLINE_LICENSE_DAYS', 30)


def offline_license_days_for_platform(platform=''):
    platform = str(platform or '').lower()
    if platform == 'android':
        return getattr(settings, 'DRM_ANDROID_OFFLINE_LICENSE_DAYS', offline_license_days())
    if platform in {'ios', 'iphone', 'ipad'}:
        return getattr(settings, 'DRM_IOS_OFFLINE_LICENSE_DAYS', offline_license_days())
    return offline_license_days()


def resolve_drm_system(asset, platform='', drm_system=''):
    requested = str(drm_system or '').lower()
    if requested in {'aes_128', 'widevine', 'fairplay', 'playready'}:
        return requested

    provider = getattr(asset, 'drm_provider', 'none')
    if provider in {'aes_128', 'widevine', 'fairplay', 'playready'}:
        return provider
    if provider != 'axinom':
        return ''

    platform = str(platform or '').lower()
    if platform in {'ios', 'iphone', 'ipad'}:
        return 'fairplay'
    if platform == 'android':
        return 'widevine'
    if platform == 'tv' and getattr(settings, 'AXINOM_PLAYREADY_LICENSE_URL', ''):
        return 'playready'
    return 'widevine'


def playback_license_ttl_seconds():
    return getattr(settings, 'DRM_LICENSE_TTL_SECONDS', 3600)


def signed_url_ttl_seconds():
    return getattr(settings, 'STREAMING_SIGNED_URL_TTL_SECONDS', 3600)


def signed_urls_enabled():
    return getattr(settings, 'STREAMING_SIGNED_URLS_ENABLED', True)


def store_video_source(asset, uploaded_file, uploader=None):
    storage_path = build_source_upload_path(asset, uploaded_file, uploader)
    saved_path = default_storage.save(storage_path, uploaded_file)

    try:
        source_url = default_storage.url(saved_path)
    except Exception:
        source_url = ''

    asset.source_file_path = saved_path
    asset.source_file_url = source_url
    asset.source_file_size_bytes = getattr(uploaded_file, 'size', 0) or 0
    asset.source_uploaded_at = timezone.now()
    asset.source_uploaded_by = uploader if getattr(uploader, 'is_authenticated', False) else None
    asset.status = 'draft'
    asset.save(update_fields=[
        'source_file_path',
        'source_file_url',
        'source_file_size_bytes',
        'source_uploaded_at',
        'source_uploaded_by',
        'status',
        'updated_at',
    ])
    return asset


def delete_video_asset_source(asset):
    """
    Supprime best-effort le master source temporaire
    associe a un VideoAsset.

    La suppression du stockage ne doit jamais bloquer
    la suppression de l objet en base.
    """
    source_path = str(
        getattr(asset, 'source_file_path', '') or ''
    ).strip()

    if not source_path:
        return {
            'deleted': 0,
            'errors': 0,
        }

    try:
        if default_storage.exists(source_path):
            default_storage.delete(source_path)

            return {
                'deleted': 1,
                'errors': 0,
            }

        return {
            'deleted': 0,
            'errors': 0,
        }
    except Exception:
        return {
            'deleted': 0,
            'errors': 1,
        }




def delete_video_asset_sources(assets):
    """
    Supprime best-effort les masters sources temporaires
    d'une collection de VideoAsset.
    """
    deleted = 0
    errors = 0

    for asset in assets:
        result = delete_video_asset_source(asset)
        deleted += result['deleted']
        errors += result['errors']

    return {
        'deleted': deleted,
        'errors': errors,
    }

def _urlsafe_hmac(secret, payload):
    digest = hmac.new(
        str(secret).encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256,
    ).digest()
    return base64.urlsafe_b64encode(digest).decode('ascii').rstrip('=')


def sign_streaming_url(url, asset, profile, user, expires_at=None):
    if not url or not signed_urls_enabled():
        return url

    expiry = expires_at or timezone.now() + timezone.timedelta(seconds=signed_url_ttl_seconds())
    expires_ts = int(expiry.timestamp())
    parts = urlsplit(url)
    query_items = parse_qsl(parts.query, keep_blank_values=True)
    query_items = [
        (key, value)
        for key, value in query_items
        if key not in {'ef_exp', 'ef_asset', 'ef_profile', 'ef_user', 'ef_sig'}
    ]
    query_items.extend([
        ('ef_exp', str(expires_ts)),
        ('ef_asset', str(asset.id)),
        ('ef_profile', str(profile.id)),
        ('ef_user', str(user.id)),
    ])

    unsigned_query = urlencode(query_items)
    payload = f"{parts.path}|{unsigned_query}"
    signature = _urlsafe_hmac(getattr(settings, 'STREAMING_SIGNING_SECRET', settings.SECRET_KEY), payload)
    query_items.append(('ef_sig', signature))
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query_items), parts.fragment))


def sign_streaming_collection_urls(items, url_field, asset, profile, user, expires_at=None):
    signed_items = []
    for item in items:
        copied = dict(item)
        copied[url_field] = sign_streaming_url(copied.get(url_field, ''), asset, profile, user, expires_at)
        signed_items.append(copied)
    return signed_items


def ensure_encryption_key_id(asset):
    if asset.drm_provider != 'none' and not asset.encryption_key_id:
        asset.encryption_key_id = uuid.uuid4().hex
        asset.save(update_fields=['encryption_key_id', 'updated_at'])
    return asset.encryption_key_id


def derive_aes128_content_key(asset):
    key_id = ensure_encryption_key_id(asset)
    payload = f"{asset.id}:{key_id}"
    digest = hmac.new(
        str(getattr(settings, 'DRM_MASTER_KEY', settings.SECRET_KEY)).encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256,
    ).digest()
    return digest[:16]


def create_playback_license(
    asset,
    profile,
    subscription,
    device_id,
    device_type='',
    offline=False,
    platform='',
    drm_system='',
):
    key_id = ensure_encryption_key_id(asset)
    resolved_drm_system = resolve_drm_system(asset, platform=platform, drm_system=drm_system)
    if offline:
        expires_at = timezone.now() + timezone.timedelta(days=offline_license_days_for_platform(platform))
    else:
        expires_at = timezone.now() + timezone.timedelta(seconds=playback_license_ttl_seconds())
    return PlaybackLicense.objects.create(
        profile=profile,
        content=asset.content,
        episode=asset.episode,
        asset=asset,
        subscription=subscription,
        device_id=device_id,
        device_type=device_type,
        license_mode='offline' if offline else 'stream',
        drm_provider=asset.drm_provider,
        key_id=key_id or '',
        expires_at=expires_at,
        last_verified_at=timezone.now(),
        metadata={
            'platform': platform or '',
            'drm_system': resolved_drm_system,
            'requested_drm_system': drm_system or '',
            'provider_license_url': provider_license_url(asset, resolved_drm_system),
            'offline_license_days': offline_license_days_for_platform(platform) if offline else None,
        },
    )


def validate_playback_license(asset, token):
    if not token:
        return None
    try:
        token_value = uuid.UUID(str(token))
    except (TypeError, ValueError):
        return None

    license_obj = (
        PlaybackLicense.objects.filter(
            asset=asset,
            license_token=token_value,
            status='active',
            expires_at__gt=timezone.now(),
        )
        .select_related('profile', 'asset', 'content')
        .first()
    )
    if not license_obj:
        return None

    license_obj.last_verified_at = timezone.now()
    license_obj.save(update_fields=['last_verified_at', 'updated_at'])
    return license_obj


def provider_license_url(asset, drm_system='', platform=''):
    resolved_drm_system = resolve_drm_system(asset, platform=platform, drm_system=drm_system)
    if asset.drm_provider == 'axinom':
        urls = {
            'widevine': getattr(settings, 'AXINOM_WIDEVINE_LICENSE_URL', ''),
            'fairplay': getattr(settings, 'AXINOM_FAIRPLAY_LICENSE_URL', ''),
            'playready': getattr(settings, 'AXINOM_PLAYREADY_LICENSE_URL', ''),
        }
        return urls.get(resolved_drm_system, '') or urls.get('widevine', '')

    mapping = {
        'aes_128': '',
        'widevine': getattr(settings, 'DRM_WIDEVINE_LICENSE_URL', ''),
        'fairplay': getattr(settings, 'DRM_FAIRPLAY_LICENSE_URL', ''),
        'playready': getattr(settings, 'DRM_PLAYREADY_LICENSE_URL', ''),
    }
    return mapping.get(resolved_drm_system or asset.drm_provider, '')


def axinom_license_urls():
    return {
        'widevine': getattr(settings, 'AXINOM_WIDEVINE_LICENSE_URL', ''),
        'fairplay': getattr(settings, 'AXINOM_FAIRPLAY_LICENSE_URL', ''),
        'playready': getattr(settings, 'AXINOM_PLAYREADY_LICENSE_URL', ''),
    }


def drm_license_urls(asset):
    if asset.drm_provider == 'axinom':
        return {key: value for key, value in axinom_license_urls().items() if value}
    if asset.drm_provider in {'widevine', 'fairplay', 'playready'}:
        return {asset.drm_provider: provider_license_url(asset)}
    return {}


def fairplay_certificate_url(asset):
    if asset.drm_provider == 'axinom':
        return (
            getattr(settings, 'AXINOM_FAIRPLAY_CERTIFICATE_URL', '')
            or getattr(settings, 'DRM_FAIRPLAY_CERTIFICATE_URL', '')
        )
    return getattr(settings, 'DRM_FAIRPLAY_CERTIFICATE_URL', '')


def _jwt_segment(payload):
    raw = json.dumps(payload, separators=(',', ':'), sort_keys=True).encode('utf-8')
    return base64.urlsafe_b64encode(raw).decode('ascii').rstrip('=')


def axinom_entitlement_token(license_obj, platform='', drm_system=''):
    """Create the Axinom v2 entitlement wrapped and signed as an LSM JWT.

    The communication secret and active-user HMAC secret are deliberately
    required. Django's application SECRET_KEY is never used as a fallback.
    """
    if not getattr(settings, 'AXINOM_DRM_ENABLED', False):
        raise ImproperlyConfigured('Axinom DRM is disabled.')

    communication_key_id = str(getattr(settings, 'AXINOM_COMMUNICATION_KEY_ID', '') or '').strip()
    communication_key_b64 = str(getattr(settings, 'AXINOM_COMMUNICATION_KEY', '') or '').strip()
    active_user_secret = str(getattr(settings, 'AXINOM_ACTIVE_USER_HMAC_SECRET', '') or '')
    if not communication_key_id or not communication_key_b64 or not active_user_secret:
        raise ImproperlyConfigured(
            'AXINOM_COMMUNICATION_KEY_ID, AXINOM_COMMUNICATION_KEY and '
            'AXINOM_ACTIVE_USER_HMAC_SECRET must be configured.'
        )

    asset = license_obj.asset
    drm_metadata = getattr(asset, 'drm_metadata', {}) or {}
    key_ids = drm_metadata.get('key_ids', {}) if isinstance(drm_metadata, dict) else {}
    resolved_drm_system = (
        str(drm_system or license_obj.metadata.get('drm_system') or '').lower()
    )
    if resolved_drm_system == 'fairplay':
        inline_keys = key_ids.get('cbcs') or []
    else:
        inline_keys = key_ids.get('cenc') or []
    if isinstance(inline_keys, str):
        inline_keys = [inline_keys]
    if not inline_keys:
        raise ImproperlyConfigured(
            f'No Axinom {resolved_drm_system or "CENC"} Key ID is stored for this asset.'
        )

    key_entries = [{'id': str(key_id)} for key_id in inline_keys if key_id]
    if not key_entries:
        raise ImproperlyConfigured('The asset has no usable Axinom Key IDs.')

    # Active Users are account-scoped: switching profiles/devices does not
    # create a new Axinom user. The source identifier is never sent to Axinom.
    principal_id = str(license_obj.profile.user_id)
    user_id = hmac.new(
        active_user_secret.encode('utf-8'),
        principal_id.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()

    expires_at = license_obj.expires_at
    offline = license_obj.license_mode == 'offline'
    license_rules = {
        'allow_persistence': bool(offline),
    }
    if offline and expires_at:
        license_rules['expiration_datetime'] = expires_at.isoformat()
    else:
        license_rules['duration'] = int(playback_license_ttl_seconds())

    entitlement_message = {
        'type': 'entitlement_message',
        'version': 2,
        'license': license_rules,
        'content_keys_source': {'inline': key_entries},
        'session': {'user_id': user_id},
    }
    usage_policy = str(getattr(settings, 'AXINOM_USAGE_POLICY_NAME', '') or '').strip()
    if usage_policy:
        for entry in key_entries:
            entry['usage_policy'] = usage_policy

    license_service_message = {
        'version': 1,
        'com_key_id': communication_key_id,
        'message': entitlement_message,
    }
    try:
        communication_key = base64.b64decode(communication_key_b64, validate=True)
    except (ValueError, TypeError) as exc:
        raise ImproperlyConfigured('AXINOM_COMMUNICATION_KEY must be valid base64.') from exc
    if not communication_key:
        raise ImproperlyConfigured('AXINOM_COMMUNICATION_KEY decodes to an empty key.')

    return jwt.encode(license_service_message, communication_key, algorithm='HS256')


def drm_configuration(asset, license_obj=None, platform='', drm_system='', offline=False):
    resolved_drm_system = resolve_drm_system(asset, platform=platform, drm_system=drm_system)
    config = {
        'provider': asset.drm_provider,
        'required': asset.drm_provider != 'none',
        'drm_system': resolved_drm_system,
        'license_url': provider_license_url(asset, resolved_drm_system),
        'license_urls': drm_license_urls(asset),
        'fairplay_certificate_url': fairplay_certificate_url(asset),
        'offline_supported_platforms': ['android', 'ios'],
        'android': {
            'drm_system': 'widevine',
            'offline_supported': True,
            'license_duration_days': offline_license_days_for_platform('android'),
        },
        'ios': {
            'drm_system': 'fairplay',
            'offline_supported': True,
            'license_duration_days': offline_license_days_for_platform('ios'),
            'certificate_url': fairplay_certificate_url(asset),
        },
    }
    if asset.drm_provider == 'axinom':
        config.update({
            'provider_name': 'Axinom DRM',
            'enabled': getattr(settings, 'AXINOM_DRM_ENABLED', False),
            'tenant_id': getattr(settings, 'AXINOM_TENANT_ID', ''),
            'policy_id': getattr(settings, 'AXINOM_POLICY_ID', ''),
        })
        if license_obj:
            config['entitlement_token'] = axinom_entitlement_token(
                license_obj,
                platform=platform,
                drm_system=drm_system,
            )
    if offline:
        config['offline'] = {
            'enabled': True,
            'platform': platform or '',
            'license_duration_days': offline_license_days_for_platform(platform),
        }
    return config
