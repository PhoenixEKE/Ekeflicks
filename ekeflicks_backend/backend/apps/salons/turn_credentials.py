"""Short-lived ICE server credentials for Coturn's TURN REST API."""

from __future__ import annotations

import base64
import hashlib
import hmac
import time

from django.conf import settings


_DEFAULT_STUN_URLS = ("stun:stun.l.google.com:19302",)
_MIN_CREDENTIAL_TTL_SECONDS = 60
_MAX_CREDENTIAL_TTL_SECONDS = 24 * 60 * 60


def _urls(setting_name: str, allowed_schemes: tuple[str, ...], fallback=()):
    configured = getattr(settings, setting_name, fallback)
    if isinstance(configured, str):
        configured = configured.split(",")

    result = []
    for value in configured or ():
        if not isinstance(value, str):
            continue
        url = value.strip()
        if url and url.lower().startswith(allowed_schemes):
            result.append(url)
    return result


def ice_server_configuration(user_id) -> dict:
    """Return public STUN settings plus expiring TURN credentials when configured."""
    stun_urls = _urls("TURN_STUN_URLS", ("stun:", "stuns:"), _DEFAULT_STUN_URLS)
    if not stun_urls:
        stun_urls = list(_DEFAULT_STUN_URLS)

    ice_servers = [{"urls": stun_urls}]
    turn_urls = _urls("TURN_ICE_SERVER_URLS", ("turn:", "turns:"))
    shared_secret = str(getattr(settings, "TURN_SHARED_SECRET", "") or "").strip()

    if not turn_urls or not shared_secret:
        return {
            "ice_servers": ice_servers,
            "relay_available": False,
            "expires_in": 0,
        }

    try:
        ttl = int(getattr(settings, "TURN_CREDENTIAL_TTL_SECONDS", 3600))
    except (TypeError, ValueError):
        ttl = 3600
    ttl = max(_MIN_CREDENTIAL_TTL_SECONDS, min(ttl, _MAX_CREDENTIAL_TTL_SECONDS))

    expires_at = int(time.time()) + ttl
    username = f"{expires_at}:{user_id}"
    # Coturn's TURN REST authentication uses an HMAC-SHA1 password.
    digest = hmac.new(
        shared_secret.encode("utf-8"),
        username.encode("utf-8"),
        hashlib.sha1,
    ).digest()
    credential = base64.b64encode(digest).decode("ascii")

    ice_servers.append(
        {
            "urls": turn_urls,
            "username": username,
            "credential": credential,
        }
    )
    return {
        "ice_servers": ice_servers,
        "relay_available": True,
        "expires_in": ttl,
    }
