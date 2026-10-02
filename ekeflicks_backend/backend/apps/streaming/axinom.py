"""Axinom Key Service integration.

Raw content keys exist only in task memory and are never written to Django,
logs, manifests, or database metadata.
"""
import base64
import hashlib
import json
import uuid
from datetime import datetime, timezone

import requests
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured


WIDEVINE_SYSTEM_ID = "edef8ba979d64acea3c827dcd51d21ed"
PLAYREADY_SYSTEM_ID = "9a04f07998404286ab92e65be0885f95"


def _required_setting(name):
    value = str(getattr(settings, name, "") or "").strip()
    if not value:
        raise ImproperlyConfigured(f"{name} must be configured to package Axinom DRM.")
    return value


def _sign_request(body: bytes) -> str:
    key = bytes.fromhex(_required_setting("AXINOM_KEY_SIGNING_KEY_HEX"))
    iv = bytes.fromhex(_required_setting("AXINOM_KEY_SIGNING_IV_HEX"))
    if len(key) != 32 or len(iv) != 16:
        raise ImproperlyConfigured("Axinom Key Service signing key/IV must be 32/16 bytes.")
    digest = hashlib.sha1(body).digest()
    padder = padding.PKCS7(algorithms.AES.block_size).padder()
    padded = padder.update(digest) + padder.finalize()
    encryptor = Cipher(algorithms.AES(key), modes.CBC(iv)).encryptor()
    return base64.b64encode(encryptor.update(padded) + encryptor.finalize()).decode("ascii")


def _decode_key_response(response):
    envelope = response.json()
    encoded = envelope.get("response")
    if not encoded:
        raise ValueError("Axinom Key Service response has no encrypted payload.")
    decoded = json.loads(base64.b64decode(encoded, validate=True))
    tracks = decoded.get("tracks")
    if not isinstance(tracks, list) or not tracks:
        raise ValueError("Axinom Key Service returned no tracks.")
    return tracks


def request_content_keys(asset):
    """Fetch an HD CENC key and a CBCS key for FairPlay.

    Return the full Axinom tracks for immediate packaging and separately return
    safe metadata suitable for persistence.
    """
    if not getattr(settings, "AXINOM_DRM_ENABLED", False):
        raise ImproperlyConfigured("AXINOM_DRM_ENABLED must be true.")
    endpoint = _required_setting("AXINOM_KEY_SERVICE_URL")
    signer = _required_setting("AXINOM_KEY_PROVIDER_NAME")
    # Stable opaque content ID; no title, email, or other identifying metadata.
    content_id = base64.b64encode(uuid.UUID(str(asset.id)).bytes).decode("ascii")
    request_data = {
        "content_id": content_id,
        "drm_types": ["WIDEVINE", "PLAYREADY", "FAIRPLAY"],
        "tracks": [{"type": "HD"}],
        "protection_scheme": "CENC",
    }
    request_text = json.dumps(request_data, indent=2, ensure_ascii=False)
    request_bytes = request_text.encode("utf-8")
    envelope = {
        "request": base64.b64encode(request_bytes).decode("ascii"),
        "signature": _sign_request(request_bytes),
        "signer": signer,
    }
    response = requests.post(
        endpoint,
        json=envelope,
        timeout=getattr(settings, "AXINOM_KEY_TIMEOUT_SECONDS", 20),
    )
    response.raise_for_status()
    tracks = _decode_key_response(response)
    safe_tracks = []
    for track in tracks:
        key_id = track.get("key_id")
        key = track.get("key")
        if not key_id or not key:
            raise ValueError("Axinom Key Service returned a track without a key or key ID.")
        try:
            key_id_hex = base64.b64decode(key_id, validate=True).hex()
            key_hex = base64.b64decode(key, validate=True).hex()
            iv_hex = base64.b64decode(track["iv"], validate=True).hex() if track.get("iv") else ""
        except (ValueError, KeyError) as exc:
            raise ValueError("Axinom Key Service returned malformed key material.") from exc
        if len(key_id_hex) != 32 or len(key_hex) != 32:
            raise ValueError("Axinom keys must use 16-byte key IDs and content keys.")
        safe_tracks.append({
            "key_id": key_id_hex,
            "scheme": str(track.get("protection_scheme") or "cenc").lower(),
            "iv": iv_hex,
            "drm": track.get("drm") or [],
        })
    safe = {
        "provider": "axinom",
        "status": "keys_ready",
        "key_ids": {
            "cenc": [t["key_id"] for t in safe_tracks if t["scheme"] == "cenc"],
            "cbcs": [t["key_id"] for t in safe_tracks if t["scheme"] == "cbcs"],
        },
        "key_tracks": safe_tracks,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    return tracks, safe


def decode_track_key(track):
    """Convert one Axinom base64 key record for a transient packager command."""
    return (
        base64.b64decode(track["key_id"], validate=True).hex(),
        base64.b64decode(track["key"], validate=True).hex(),
    )
