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

## Live validation still required

Use Axinom test credentials and a non-production asset first. Verify generated DASH CENC signaling, HLS FairPlay signaling, license issuance, and playback on Android, iOS, web, and TV. Widevine and FairPlay native playback require platform-specific players and licenses; PlayReady requires a compatible TV or browser runtime. Offline license persistence and renew/revoke behavior must be validated on real devices before being enabled to customers.
