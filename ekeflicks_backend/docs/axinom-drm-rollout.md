# Axinom DRM configuration

Set these values in the backend `.env` file; do not commit credentials.

```dotenv
AXINOM_DRM_ENABLED=false
AXINOM_TENANT_ID=
AXINOM_POLICY_ID=
AXINOM_COMMUNICATION_KEY_ID=
AXINOM_COMMUNICATION_KEY=
AXINOM_ACTIVE_USER_HMAC_SECRET=
AXINOM_USAGE_POLICY_NAME=
AXINOM_KEY_SERVICE_URL=https://key-server-management.axprod.net/api/WidevineProtectionInfo
AXINOM_KEY_PROVIDER_NAME=
AXINOM_KEY_SIGNING_KEY_HEX=
AXINOM_KEY_SIGNING_IV_HEX=
AXINOM_KEY_TIMEOUT_SECONDS=20
AXINOM_WIDEVINE_LICENSE_URL=
AXINOM_PLAYREADY_LICENSE_URL=
AXINOM_FAIRPLAY_LICENSE_URL=
AXINOM_FAIRPLAY_CERTIFICATE_URL=
```

`AXINOM_COMMUNICATION_KEY` is the Axinom communication key encoded as Base64. The Key Service signing key and IV are hexadecimal values. Keep the active-user HMAC secret independent from Django's `DJANGO_SECRET_KEY`.

The playback identity sent to Axinom is an HMAC-SHA256 pseudonym based on the primary user account ID. It is shared by profiles on that account; profile IDs, email addresses, and phone numbers are not sent as Axinom Active User IDs. Raw content keys must exist only in the packaging task's memory. Persist only Key IDs, protection system metadata, packaging/QC status, and admin review records.

## Publication gate

An Axinom asset must have encrypted packaging marked ready and admin approval for Widevine, FairPlay, and PlayReady before publication. The DRM review endpoint is `POST /api/v1/streaming/video-assets/{id}/drm-review/` with `{"system":"widevine|fairplay|playready","decision":"approved|rejected","reason":"..."}`. This endpoint records review metadata; it does not substitute for packaging or device playback validation.

## Client playback wiring

The Flutter client reads the published `video_asset_id`, requests a signed manifest and short-lived playback entitlement, and configures Better Player for Widevine on Android/Chromium and FairPlay on iOS/Safari. It stops with an error if the protected manifest or entitlement is missing; it does not fall back to a clear asset URL. The entitlement is held in memory, sent as `X-AxDRM-Message` for Widevine, and passed as Axinom's `AxDrmMessage` license query parameter for FairPlay.

The client build uses Flutter 3.47, Android compile SDK 36, and iOS 13 as its minimum deployment target. Web playback loads Shaka Player 4.7.11 from cdnjs, so that CDN must be reachable and allowed by the site's Content Security Policy.

## Live validation still required

Use Axinom test credentials and a non-production asset first. Verify generated DASH CENC signaling, HLS FairPlay signaling, license issuance, and playback on Android, iOS, web, and Android TV. Confirm the Axinom FairPlay license endpoint accepts the query-based entitlement, and validate certificate, CORS, and Content Security Policy settings on the actual domains. PlayReady packaging and admin approval exist; the Flutter client does not advertise PlayReady playback and still needs a compatible TV/browser player integration. Offline license persistence, renewal, and revocation are not enabled in the client and must be validated on devices before customer availability.
