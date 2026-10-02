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
    """Fetch separate CENC and CBCS key material.

    Return raw Key Service tracks for immediate packaging and safe metadata
    suitable for persistence. Raw keys must remain in process memory only.
    """
    if not getattr(settings, "AXINOM_DRM_ENABLED", False):
        raise ImproperlyConfigured("AXINOM_DRM_ENABLED must be true.")
    endpoint = _required_setting("AXINOM_KEY_SERVICE_URL")
    signer = _required_setting("AXINOM_KEY_PROVIDER_NAME")
    content_id = base64.b64encode(uuid.UUID(str(asset.id)).bytes).decode("ascii")
    all_tracks = []
    safe_tracks = []
    for scheme in ("CENC", "CBCS"):
        request_data = {
            "content_id": content_id,
            "drm_types": ["WIDEVINE", "PLAYREADY", "FAIRPLAY"],
            "tracks": [{"type": "HD"}],
            "protection_scheme": scheme,
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
        scheme_tracks = _decode_key_response(response)
        for track in scheme_tracks:
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
            # Keep the normalized scheme on the in-memory record for packaging.
            normalized = dict(track)
            normalized["_scheme"] = scheme.lower()
            all_tracks.append(normalized)
            safe_tracks.append({
                "key_id": str(uuid.UUID(hex=key_id_hex)),
                "scheme": scheme.lower(),
                "iv": iv_hex,
                "drm_systems": [
                    str(item.get("system") or "").lower()
                    for item in (track.get("drm") or [])
                    if isinstance(item, dict)
                ],
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
    return all_tracks, safe

def decode_track_key(track):
    """Convert one Axinom base64 key record for a transient packager command."""
    return (
        base64.b64decode(track["key_id"], validate=True).hex(),
        base64.b64decode(track["key"], validate=True).hex(),
    )

def package_video_asset(asset, source_path, renditions, output_root, dash_root, segment_duration, has_audio):
    """Encode a per-title ladder, encrypt it with Axinom keys, and package DASH/HLS.

    This runs locally in a worker temporary directory. Raw keys are passed to
    Shaka Packager only through its process arguments and are never persisted.
    """
    import subprocess
    from pathlib import Path

    output_root = Path(output_root)
    dash_root = Path(dash_root)
    output_root.mkdir(parents=True, exist_ok=True)
    dash_root.mkdir(parents=True, exist_ok=True)

    raw_tracks, safe_metadata = request_content_keys(asset)
    cenc = next((track for track in raw_tracks if track["_scheme"] == "cenc"), None)
    cbcs = next((track for track in raw_tracks if track["_scheme"] == "cbcs"), None)
    if cenc is None or cbcs is None:
        raise ValueError("Axinom did not return both CENC and CBCS content keys.")
    cenc_key_id, cenc_key = decode_track_key(cenc)
    cbcs_key_id, cbcs_key = decode_track_key(cbcs)
    cbcs_iv = base64.b64decode(cbcs["iv"], validate=True).hex() if cbcs.get("iv") else ""
    if not cbcs_iv:
        raise ValueError("Axinom did not return the IV required for FairPlay HLS.")

    work = output_root.parent / "encoded"
    work.mkdir(parents=True, exist_ok=True)
    encoded = []
    for index, rendition in enumerate(renditions):
        target = work / f"video_{index}_{rendition['quality']}.mp4"
        bitrate = str(int(rendition["bandwidth"]))
        subprocess.run([
            "ffmpeg", "-y", "-i", str(source_path), "-map", "0:v:0",
            "-vf", f"scale=-2:{int(rendition['height'])}",
            "-c:v", "libx264", "-profile:v", "main", "-preset", "veryfast",
            "-b:v", bitrate, "-maxrate", bitrate, "-bufsize", str(int(bitrate) * 2),
            "-force_key_frames", f"expr:gte(t,n_forced*{segment_duration})",
            "-sc_threshold", "0", "-an", "-movflags", "+faststart", str(target),
        ], check=True, capture_output=True, text=True)
        encoded.append((target, rendition, index))

    audio_path = None
    if has_audio:
        audio_path = work / "audio.mp4"
        subprocess.run([
            "ffmpeg", "-y", "-i", str(source_path), "-map", "0:a:0",
            "-vn", "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart",
            str(audio_path),
        ], check=True, capture_output=True, text=True)

    def run_packager(scheme, key_id, key, systems, output_hls_root, mpd_path=None, iv=None):
        output_hls_root.mkdir(parents=True, exist_ok=True)
        args = ["packager"]
        for target, rendition, index in encoded:
            quality = rendition["quality"]
            base = output_hls_root / quality
            base.mkdir(parents=True, exist_ok=True)
            args.append(
                f"in={target},stream=video,"
                f"init_segment={base}/init.mp4,"
                f"segment_template={base}/segment_$Number$.m4s,"
                f"playlist_name={quality}/index.m3u8,hls_name={quality}"
            )
        if audio_path:
            audio_dir = output_hls_root / "audio"
            audio_dir.mkdir(parents=True, exist_ok=True)
            args.append(
                f"in={audio_path},stream=audio,"
                f"init_segment={audio_dir}/init.mp4,"
                f"segment_template={audio_dir}/segment_$Number$.m4s,"
                "playlist_name=audio/index.m3u8,hls_name=audio"
            )
        args.extend([
            "--enable_raw_key_encryption",
            f"--keys=key_id={key_id}:key={key}",
            f"--protection_scheme={scheme}",
            f"--protection_systems={systems}",
            "--segment_duration", str(segment_duration),
            f"--hls_master_playlist_output={output_hls_root}/master.m3u8",
        ])
        if iv:
            args.append(f"--hls_key_uri=skd://{uuid.UUID(hex=key_id)}:{iv}")
        if mpd_path:
            args.append(f"--mpd_output={mpd_path}")
        subprocess.run(args, check=True, capture_output=True, text=True)

    run_packager(
        "cenc", cenc_key_id, cenc_key, "Widevine,PlayReady",
        output_root, dash_root / "manifest.mpd",
    )
    fairplay_root = output_root / "fairplay"
    run_packager(
        "cbcs", cbcs_key_id, cbcs_key, "FairPlay",
        fairplay_root, iv=cbcs_iv,
    )

    safe_metadata.update({
        "packaging_status": "packaged",
        "packaging_systems": ["widevine", "playready", "fairplay"],
        "manifests": {
            "widevine_hls": "master.m3u8",
            "widevine_dash": "manifest.mpd",
            "playready_dash": "manifest.mpd",
            "fairplay_hls": "fairplay/master.m3u8",
        },
        "validation": {},
    })
    rendition_payloads = [(index, rendition) for _, rendition, index in encoded]
    return rendition_payloads, safe_metadata

