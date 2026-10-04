import json
import uuid
from datetime import timedelta
from unittest.mock import MagicMock, patch

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from core.models import (
    AdCampaign,
    AdEvent,
    Content,
    Genre,
    Profile,
    Subscription,
    SubscriptionPlan,
    User,
    VideoAsset,
    ViewingSession,
)


class AdvertisingPlaybackApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="ads-viewer@example.com",
            password="StrongPass123",
            firstname="Viewer",
        )
        self.profile = Profile.objects.get(user=self.user)
        self.profile.age = 26
        self.profile.country_code = "CI"
        self.profile.save(update_fields=["age", "country_code", "updated_at"])
        self.plan = SubscriptionPlan.objects.create(
            name="Ad supported",
            slug="ad-supported-test",
            price="5.00",
            duration_days=30,
            ads_included=True,
        )
        self.subscription = Subscription.objects.create(
            user=self.user,
            plan=self.plan,
            status="active",
            expires_at=timezone.now() + timedelta(days=30),
        )
        self.content = Content.objects.create(
            title="Film de test",
            type="movie",
            producer_submission_status="approved",
        )
        self.asset = VideoAsset.objects.create(
            content=self.content,
            hls_master_url="https://cdn.ekeflicks.test/film/master.m3u8",
            dash_manifest_url="https://cdn.ekeflicks.test/film/manifest.mpd",
            status="ready",
            moderation_status="approved",
            published_at=timezone.now(),
        )
        self.client.force_authenticate(user=self.user)

    def _decision(self, *, placement="preroll", platform="web", session_id=None):
        return self.client.post(
            "/api/v1/ads/decision/",
            {
                "asset_id": str(self.asset.pk),
                "profile_id": str(self.profile.pk),
                "placement": placement,
                "platform": platform,
                "drm_system": "playready" if platform == "tv" else "widevine",
                "playback_session_id": str(session_id or uuid.uuid4()),
            },
            format="json",
        )

    def _campaign(self, **overrides):
        values = {
            "name": "Campagne de test",
            "advertiser": "Annonceur",
            "status": "active",
            "delivery_mode": "client_side",
            "formats": ["preroll"],
            "media_url": "https://ads.ekeflicks.test/creative.mp4",
            "media_duration_seconds": 15,
            "frequency_cap_per_day": 3,
        }
        values.update(overrides)
        return AdCampaign.objects.create(**values)

    def test_ad_free_subscription_never_receives_ad_decision(self):
        self.subscription.ads_included_at_purchase = False
        self.subscription.save(update_fields=["ads_included_at_purchase"])
        self._campaign()

        response = self._decision()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["reason"], "ad_free_plan")
        self.assertIsNone(response.data["ad"])

    def test_client_side_preroll_and_idempotent_measurement(self):
        campaign = self._campaign()
        session_id = uuid.uuid4()

        decision = self._decision(session_id=session_id)
        self.assertEqual(decision.status_code, 200)
        self.assertEqual(decision.data["delivery"], "client_side")
        self.assertEqual(decision.data["ad"]["campaign_id"], str(campaign.pk))
        self.assertTrue(AdEvent.objects.filter(
            campaign=campaign,
            playback_session_id=session_id,
            event_type="filled",
            placement="preroll",
        ).exists())

        event_id = uuid.uuid4()
        payload = {
            "event_id": str(event_id),
            "campaign_id": str(campaign.pk),
            "asset_id": str(self.asset.pk),
            "profile_id": str(self.profile.pk),
            "placement": "preroll",
            "platform": "web",
            "playback_session_id": str(session_id),
            "event_type": "impression",
        }
        first = self.client.post("/api/v1/ads/events/", payload, format="json")
        duplicate = self.client.post("/api/v1/ads/events/", payload, format="json")

        self.assertEqual(first.status_code, 202)
        self.assertFalse(first.data["duplicate"])
        self.assertEqual(duplicate.status_code, 202)
        self.assertTrue(duplicate.data["duplicate"])
        self.assertEqual(AdEvent.objects.filter(event_id=event_id).count(), 1)

    def test_targeting_history_requires_explicit_adult_profile_consent(self):
        genre = Genre.objects.create(name="Drame", slug="drame")
        self.content.genres.add(genre)
        ViewingSession.objects.create(profile=self.profile, content=self.content)
        campaign = self._campaign(interest_tags=["drame"])

        without_consent = self._decision()
        self.assertEqual(without_consent.data["delivery"], "none")

        consent = self.client.put(
            f"/api/v1/profiles/{self.profile.pk}/ad-targeting-consent/",
            {"personalized_ads": True},
            format="json",
        )
        self.assertEqual(consent.status_code, 200)
        self.assertTrue(consent.data["personalized_ads"])

        with_consent = self._decision()
        self.assertEqual(with_consent.data["ad"]["campaign_id"], str(campaign.pk))

    def test_underage_profile_cannot_enable_personalized_ads(self):
        self.profile.age = 17
        self.profile.save(update_fields=["age", "updated_at"])

        rejected = self.client.put(
            f"/api/v1/profiles/{self.profile.pk}/ad-targeting-consent/",
            {"personalized_ads": True},
            format="json",
        )

        self.assertEqual(rejected.status_code, 403)
        self.assertFalse(AdEvent.objects.filter(profile=self.profile, event_type="impression").exists())

    def test_tv_does_not_receive_client_side_video_ad(self):
        self._campaign()

        response = self._decision(platform="tv")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["delivery"], "none")

    def test_ssai_midroll_can_share_session_with_client_preroll(self):
        self._campaign(name="Client pre-roll")
        self._campaign(
            name="SSAI mid-roll",
            delivery_mode="ssai",
            formats=["midroll"],
            media_url="",
            vast_tag_url="https://ads.vendor.test/midroll.vast",
            cue_points_seconds=[600],
        )
        endpoint = "https://stitcher.vendor.test/session"
        mock_response = MagicMock()
        mock_response.geturl.return_value = endpoint
        mock_response.read.return_value = json.dumps({
            "manifest_url": "https://manifest.vendor.test/session/manifest.mpd",
        }).encode("utf-8")
        context_manager = MagicMock()
        context_manager.__enter__.return_value = mock_response

        with override_settings(
            AD_SSAI_ENABLED=True,
            AD_SSAI_SESSION_URL=endpoint,
            AD_SSAI_ALLOWED_HOSTS=["manifest.vendor.test"],
        ), patch(
            "apps.streaming.advertising_api.urlopen",
            return_value=context_manager,
        ):
            response = self._decision()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["delivery"], "ssai")
        self.assertEqual(response.data["ad"]["delivery_mode"], "client_side")
        self.assertEqual(response.data["ssai_breaks"][0]["placement"], "midroll")
        self.assertEqual(response.data["ssai_breaks"][0]["cue_point_seconds"], 600)

    def test_ssai_uses_allowlisted_https_manifest_and_records_fills(self):
        campaign = self._campaign(
            delivery_mode="ssai",
            media_url="",
            vast_tag_url="https://ads.vendor.test/tag.vast",
        )
        endpoint = "https://stitcher.vendor.test/session"
        mock_response = MagicMock()
        mock_response.geturl.return_value = endpoint
        mock_response.read.return_value = json.dumps({
            "session_id": "stitched-session-1",
            "manifest_url": "https://manifest.vendor.test/session/manifest.mpd",
        }).encode("utf-8")
        context_manager = MagicMock()
        context_manager.__enter__.return_value = mock_response

        with override_settings(
            AD_SSAI_ENABLED=True,
            AD_SSAI_SESSION_URL=endpoint,
            AD_SSAI_API_KEY="test-only-key",
            AD_SSAI_ALLOWED_HOSTS=["manifest.vendor.test"],
            AD_SSAI_TIMEOUT_SECONDS=5,
        ), patch(
            "apps.streaming.advertising_api.urlopen",
            return_value=context_manager,
        ) as ssai_request:
            response = self._decision(platform="tv")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["delivery"], "ssai")
        self.assertEqual(response.data["manifest_url"], "https://manifest.vendor.test/session/manifest.mpd")
        self.assertEqual(response.data["ssai_session_id"], "stitched-session-1")
        self.assertEqual(response.data["ssai_breaks"][0]["campaign_id"], str(campaign.pk))
        self.assertTrue(AdEvent.objects.filter(
            campaign=campaign,
            event_type="filled",
            placement="preroll",
        ).exists())
        self.assertEqual(ssai_request.call_count, 1)
