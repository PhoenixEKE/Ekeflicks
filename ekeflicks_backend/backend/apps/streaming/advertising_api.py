import json
import logging
import uuid
from datetime import timedelta
from urllib.parse import urlsplit
from urllib.request import Request as UrlRequest, urlopen

from django.conf import settings
from django.db import IntegrityError
from django.utils import timezone
from rest_framework import exceptions, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.streaming.services import get_active_subscription, sign_streaming_url
from core.models import AdCampaign, AdEvent, AdTargetingConsent, Profile, VideoAsset, ViewingSession


logger = logging.getLogger(__name__)
_CLIENT_EVENT_TYPES = {"impression", "start", "first_quartile", "midpoint", "third_quartile", "complete", "skip", "click", "error"}
_VALID_PLATFORMS = {"web", "android", "ios", "tv"}


def _ad_supported(user):
    subscription = get_active_subscription(user)
    if not subscription:
        return True
    allowed = subscription.ads_included_at_purchase
    if allowed is None:
        allowed = getattr(subscription.plan, "ads_included", False)
    return bool(allowed)


def _personalization_allowed(profile):
    if profile.type.name == "child" or profile.age is None or profile.age < 18:
        return False
    return AdTargetingConsent.objects.filter(profile=profile, personalized_ads=True).exists()


def _watched_genres(profile, enabled):
    if not enabled:
        return set()
    since = timezone.now() - timedelta(days=90)
    names = ViewingSession.objects.filter(
        profile=profile,
        start_time__gte=since,
    ).values_list("content__genres__name", flat=True).distinct()
    return {str(name).strip().lower() for name in names if name}


def _campaign_is_eligible(campaign, profile, content, placement, country, watched, consented, now):
    if campaign.status != "active" or placement not in (campaign.formats or []):
        return False
    if campaign.active_from and campaign.active_from > now:
        return False
    if campaign.active_until and campaign.active_until <= now:
        return False
    targeted_content_ids = {item.pk for item in campaign.contents.all()}
    if targeted_content_ids and content.pk not in targeted_content_ids:
        return False
    target_countries = {str(code).upper() for code in (campaign.target_countries or [])}
    if target_countries and (not country or country.upper() not in target_countries):
        return False
    current_genres = {str(name).strip().lower() for name in content.genres.values_list("name", flat=True)}
    contextual = {str(tag).strip().lower() for tag in (campaign.contextual_genres or [])}
    if contextual and not current_genres.intersection(contextual):
        return False
    interests = {str(tag).strip().lower() for tag in (campaign.interest_tags or [])}
    if interests and (not consented or not watched.intersection(interests)):
        return False
    if campaign.target_age_min is not None or campaign.target_age_max is not None:
        if not consented or profile.age is None or profile.age < 18:
            return False
        if campaign.target_age_min is not None and profile.age < campaign.target_age_min:
            return False
        if campaign.target_age_max is not None and profile.age > campaign.target_age_max:
            return False
    if campaign.frequency_cap_per_day:
        day_start = timezone.localdate()
        impressions_today = AdEvent.objects.filter(
            campaign=campaign,
            profile=profile,
            event_type="impression",
            occurred_at__date=day_start,
        ).count()
        if impressions_today >= campaign.frequency_cap_per_day:
            return False
    return True


def _campaigns_for(profile, content, placement, country, watched, consented, now):
    candidates = AdCampaign.objects.filter(status="active").prefetch_related("contents").order_by("-priority", "-created_at")[:500]
    return [
        campaign for campaign in candidates
        if _campaign_is_eligible(campaign, profile, content, placement, country, watched, consented, now)
    ]


def _cue_schedule(profile, content, country, watched, consented, now):
    points = set()
    for campaign in _campaigns_for(profile, content, "midroll", country, watched, consented, now):
        points.update(
            int(point) for point in (campaign.cue_points_seconds or [])
            if str(point).isdigit() and int(point) > 0
        )
    return sorted(points)


def _weighted_pick(candidates):
    if not candidates:
        return None
    highest_priority = max(campaign.priority for campaign in candidates)
    top = [campaign for campaign in candidates if campaign.priority == highest_priority]
    weights = [max(int(campaign.delivery_weight or 1), 1) for campaign in top]
    return __import__("random").choices(top, weights=weights, k=1)[0]


def _creative(campaign, placement):
    return {
        "campaign_id": str(campaign.pk),
        "name": campaign.name,
        "advertiser": campaign.advertiser,
        "placement": placement,
        "media_url": campaign.media_url,
        "image_url": campaign.image_url,
        "cta_label": campaign.cta_label,
        "cta_url": campaign.cta_url,
        "skip_after_seconds": campaign.skip_after_seconds,
        "duration_seconds": campaign.media_duration_seconds,
        "delivery_mode": campaign.delivery_mode,
    }


def _record(campaign, profile, content, playback_session_id, event_type, placement, platform, position=0):
    return AdEvent.objects.create(
        campaign=campaign,
        profile=profile,
        content=content,
        playback_session_id=playback_session_id,
        event_type=event_type,
        placement=placement,
        device_type=platform,
        country_code=(profile.country_code or "").upper()[:2],
        position_seconds=max(int(position or 0), 0),
    )


def _source_manifest(asset, profile, user, platform, drm_system):
    metadata = asset.drm_metadata if isinstance(asset.drm_metadata, dict) else {}
    manifests = metadata.get("manifests") or {}
    drm_system = (drm_system or "").lower()
    if asset.drm_provider == "axinom":
        keys = {
            "fairplay": ("fairplay_hls",),
            "playready": ("playready_dash",),
            "widevine": ("widevine_dash", "widevine_hls"),
        }.get(drm_system, ())
        source = next((manifests.get(key) for key in keys if manifests.get(key)), "")
    elif platform == "tv" or drm_system in {"widevine", "playready"}:
        source = asset.dash_manifest_url or asset.hls_master_url
    else:
        source = asset.hls_master_url or asset.dash_manifest_url
    expires = timezone.now() + timedelta(seconds=int(getattr(settings, "STREAMING_SIGNED_URL_TTL_SECONDS", 3600)))
    return sign_streaming_url(source, asset, profile, user, expires)


def _ssai_configured():
    return bool(
        getattr(settings, "AD_SSAI_ENABLED", False)
        and str(getattr(settings, "AD_SSAI_SESSION_URL", "")).strip()
    )


def _request_ssai_session(asset, profile, request, platform, drm_system, playback_session_id, breaks):
    endpoint = str(settings.AD_SSAI_SESSION_URL).strip()
    parsed_endpoint = urlsplit(endpoint)
    if parsed_endpoint.scheme != "https" or not parsed_endpoint.hostname:
        raise ValueError("SSAI endpoint must use HTTPS")
    manifest_url = _source_manifest(asset, profile, request.user, platform, drm_system)
    if not manifest_url or urlsplit(manifest_url).scheme != "https":
        raise ValueError("A signed HTTPS source manifest is required for SSAI")
    payload = {
        "asset_id": str(asset.pk),
        "content_id": str(asset.content_id),
        "playback_session_id": str(playback_session_id),
        "source_manifest_url": manifest_url,
        "platform": platform,
        "drm_system": drm_system,
        "breaks": breaks,
    }
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    api_key = str(getattr(settings, "AD_SSAI_API_KEY", "")).strip()
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    outgoing = UrlRequest(endpoint, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
    timeout = min(max(int(getattr(settings, "AD_SSAI_TIMEOUT_SECONDS", 5)), 1), 15)
    with urlopen(outgoing, timeout=timeout) as response:
        final_url = urlsplit(response.geturl() if hasattr(response, "geturl") else endpoint)
        if final_url.scheme != "https" or final_url.hostname != parsed_endpoint.hostname:
            raise ValueError("SSAI session endpoint redirected to an untrusted host")
        raw = response.read(1024 * 1024 + 1)
    if len(raw) > 1024 * 1024:
        raise ValueError("SSAI response too large")
    result = json.loads(raw.decode("utf-8"))
    stitched_url = str(result.get("manifest_url") or result.get("session_manifest_url") or "").strip()
    parts = urlsplit(stitched_url)
    if parts.scheme != "https" or not parts.hostname:
        raise ValueError("SSAI provider returned an invalid manifest URL")
    allowed_hosts = {host.lower() for host in getattr(settings, "AD_SSAI_ALLOWED_HOSTS", [])}
    if not allowed_hosts:
        allowed_hosts = {parsed_endpoint.hostname.lower()}
    if parts.hostname.lower() not in allowed_hosts:
        raise ValueError("SSAI manifest host is not allow-listed")
    return {
        "manifest_url": stitched_url,
        "session_id": str(result.get("session_id") or playback_session_id)[:160],
    }


def _playback_session_id(value):
    if not value:
        return uuid.uuid4()
    try:
        return uuid.UUID(str(value))
    except (TypeError, ValueError, AttributeError):
        raise exceptions.ValidationError({"playback_session_id": "Identifiant de session invalide."})


class AdDecisionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        asset = VideoAsset.objects.select_related("content").filter(
            pk=request.data.get("asset_id"),
            status="ready",
            moderation_status="approved",
            content__producer_submission_status="approved",
        ).first()
        if not asset:
            raise exceptions.NotFound("La vidéo n’est pas disponible pour la publicité.")
        profile = Profile.objects.select_related("type").filter(
            pk=request.data.get("profile_id"),
            user=request.user,
            is_active=True,
        ).first()
        if not profile:
            raise exceptions.PermissionDenied("Profil actif invalide.")
        if not _ad_supported(request.user):
            return Response({"ad": None, "delivery": "none", "reason": "ad_free_plan", "ad_schedule": []})

        placement = str(request.data.get("placement") or "").strip().lower()
        if placement not in {"preroll", "midroll", "pause"}:
            raise exceptions.ValidationError({"placement": "Valeurs autorisées : preroll, midroll, pause."})
        platform = str(request.data.get("platform") or "web").strip().lower()
        if platform not in _VALID_PLATFORMS:
            raise exceptions.ValidationError({"platform": "Plateforme non reconnue."})
        drm_system = str(request.data.get("drm_system") or "").strip().lower()
        if drm_system not in {"widevine", "fairplay", "playready"}:
            raise exceptions.ValidationError({"drm_system": "Système DRM non reconnu."})
        expected_drm = {"android": "widevine", "ios": "fairplay", "tv": "playready"}
        if platform in expected_drm and drm_system != expected_drm[platform]:
            raise exceptions.ValidationError({"drm_system": "Le DRM ne correspond pas à cette plateforme."})
        if platform == "web" and drm_system not in {"widevine", "fairplay"}:
            raise exceptions.ValidationError({"drm_system": "Le DRM web doit être Widevine ou FairPlay."})
        try:
            position = max(0, min(int(request.data.get("position_seconds") or 0), 86400))
        except (TypeError, ValueError):
            raise exceptions.ValidationError({"position_seconds": "Position de lecture invalide."})
        playback_session_id = _playback_session_id(request.data.get("playback_session_id"))
        now = timezone.now()
        country = (profile.country_code or "").upper()
        consented = _personalization_allowed(profile)
        watched = _watched_genres(profile, consented)
        schedule = _cue_schedule(profile, asset.content, country, watched, consented, now) if placement == "preroll" else []

        _record(None, profile, asset.content, playback_session_id, "request", placement, platform, position)
        candidates = _campaigns_for(profile, asset.content, placement, country, watched, consented, now)
        selected = _weighted_pick(candidates)

        if placement == "preroll":
            server_breaks = []
            for slot in ("preroll", "midroll"):
                server_candidates = [
                    campaign for campaign in _campaigns_for(profile, asset.content, slot, country, watched, consented, now)
                    if campaign.delivery_mode == "ssai"
                ]
                if slot == "midroll":
                    campaigns_by_point = {}
                    for campaign in server_candidates:
                        for point in campaign.cue_points_seconds or []:
                            if str(point).isdigit() and int(point) > 0:
                                campaigns_by_point.setdefault(int(point), []).append(campaign)
                    for point, point_candidates in sorted(campaigns_by_point.items()):
                        campaign = _weighted_pick(point_candidates)
                        server_breaks.append({
                            "campaign_id": str(campaign.pk),
                            "placement": "midroll",
                            "cue_point_seconds": point,
                            "creative_url": campaign.vast_tag_url or campaign.media_url,
                            "name": campaign.name,
                            "advertiser": campaign.advertiser,
                            "cta_label": campaign.cta_label,
                            "cta_url": campaign.cta_url,
                            "duration_seconds": campaign.media_duration_seconds,
                        })
                else:
                    campaign = _weighted_pick(server_candidates)
                    if campaign:
                        server_breaks.append({
                            "campaign_id": str(campaign.pk),
                            "placement": "preroll",
                            "creative_url": campaign.vast_tag_url or campaign.media_url,
                            "name": campaign.name,
                            "advertiser": campaign.advertiser,
                            "cta_label": campaign.cta_label,
                            "cta_url": campaign.cta_url,
                            "duration_seconds": campaign.media_duration_seconds,
                        })
            if server_breaks:
                has_server_preroll = any(item["placement"] == "preroll" for item in server_breaks)
                if not _ssai_configured():
                    selected_client = _weighted_pick([item for item in candidates if item.delivery_mode == "client_side"])
                    if not selected_client:
                        return Response({
                            "ad": None, "delivery": "none", "reason": "ssai_unconfigured",
                            "ad_schedule": schedule,
                        })
                    selected = selected_client
                else:
                    try:
                        provider = _request_ssai_session(
                            asset, profile, request, platform, drm_system, playback_session_id, server_breaks,
                        )
                    except Exception:
                        logger.warning("SSAI session creation failed for asset %s.", asset.pk, exc_info=True)
                        selected_client = _weighted_pick([item for item in candidates if item.delivery_mode == "client_side"])
                        if selected_client and platform != "tv":
                            selected = selected_client
                            _record(selected, profile, asset.content, playback_session_id, "filled", placement, platform, position)
                            return Response({
                                "ad": _creative(selected, placement),
                                "delivery": "client_side",
                                "manifest_url": "",
                                "ad_schedule": schedule,
                                "reason": "ssai_fallback",
                            })
                        return Response({"ad": None, "delivery": "none", "reason": "ssai_unavailable", "ad_schedule": schedule})
                    for slot_item in server_breaks:
                        campaign = next((item for item in AdCampaign.objects.filter(pk=slot_item["campaign_id"])[:1]), None)
                        if campaign:
                            _record(campaign, profile, asset.content, playback_session_id, "filled", slot_item["placement"], platform)
                    client_preroll = None
                    if not has_server_preroll and platform != "tv":
                        client_preroll = _weighted_pick([
                            item for item in candidates if item.delivery_mode == "client_side"
                        ])
                        if client_preroll:
                            _record(client_preroll, profile, asset.content, playback_session_id, "filled", "preroll", platform)
                    return Response({
                        "ad": _creative(client_preroll, "preroll") if client_preroll else None,
                        "delivery": "ssai",
                        "manifest_url": provider["manifest_url"],
                        "ssai_session_id": provider["session_id"],
                        "ad_schedule": schedule,
                        "ssai_breaks": server_breaks,
                    })

        if platform == "tv" and placement != "pause" and selected and selected.delivery_mode != "ssai":
            selected = None
        if placement != "preroll" and selected and selected.delivery_mode == "ssai":
            selected = _weighted_pick([item for item in candidates if item.delivery_mode == "client_side"])
        if not selected:
            return Response({"ad": None, "delivery": "none", "reason": "no_fill", "ad_schedule": schedule})
        _record(selected, profile, asset.content, playback_session_id, "filled", placement, platform, position)
        return Response({
            "ad": _creative(selected, placement),
            "delivery": selected.delivery_mode,
            "manifest_url": "",
            "ad_schedule": schedule,
        })


class AdEventView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        event_type = str(request.data.get("event_type") or "").strip().lower()
        if event_type not in _CLIENT_EVENT_TYPES:
            raise exceptions.ValidationError({"event_type": "Événement publicitaire invalide."})
        placement = str(request.data.get("placement") or "").strip().lower()
        if placement not in {"preroll", "midroll", "pause"}:
            raise exceptions.ValidationError({"placement": "Emplacement invalide."})
        platform = str(request.data.get("platform") or "web").strip().lower()
        if platform not in _VALID_PLATFORMS:
            raise exceptions.ValidationError({"platform": "Plateforme non reconnue."})

        profile = Profile.objects.select_related("type").filter(
            pk=request.data.get("profile_id"),
            user=request.user,
            is_active=True,
        ).first()
        if not profile:
            raise exceptions.PermissionDenied("Profil actif invalide.")
        campaign = AdCampaign.objects.filter(pk=request.data.get("campaign_id")).first()
        if not campaign:
            raise exceptions.NotFound("Campagne publicitaire introuvable.")
        asset = VideoAsset.objects.select_related("content").filter(pk=request.data.get("asset_id")).first()
        if not asset or (campaign.contents.exists() and not campaign.contents.filter(pk=asset.content_id).exists()):
            raise exceptions.PermissionDenied("La publicité ne correspond pas à cette vidéo.")
        session_id = _playback_session_id(request.data.get("playback_session_id"))
        if not AdEvent.objects.filter(
            campaign=campaign,
            profile=profile,
            playback_session_id=session_id,
            event_type="filled",
            placement=placement,
        ).exists():
            raise exceptions.PermissionDenied("Aucune décision publicitaire active pour cette session.")
        try:
            position = max(0, min(int(request.data.get("position_seconds") or 0), 86400))
        except (TypeError, ValueError):
            raise exceptions.ValidationError({"position_seconds": "Position de lecture invalide."})
        try:
            event_id = uuid.UUID(str(request.data.get("event_id"))) if request.data.get("event_id") else uuid.uuid4()
        except (TypeError, ValueError, AttributeError):
            raise exceptions.ValidationError({"event_id": "Identifiant d’événement invalide."})
        defaults = {
            "campaign": campaign,
            "content": asset.content,
            "profile": profile,
            "playback_session_id": session_id,
            "event_type": event_type,
            "placement": placement,
            "device_type": platform,
            "country_code": (profile.country_code or "").upper()[:2],
            "position_seconds": position,
            "metadata": {},
        }
        try:
            _, created = AdEvent.objects.get_or_create(event_id=event_id, defaults=defaults)
        except IntegrityError:
            created = False
        return Response({"accepted": True, "duplicate": not created}, status=status.HTTP_202_ACCEPTED)
