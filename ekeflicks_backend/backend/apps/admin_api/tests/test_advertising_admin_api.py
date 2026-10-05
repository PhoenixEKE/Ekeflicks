from datetime import timedelta

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.admin_api.security import totp
from core.models import AdCampaign, AdminMFADevice, Content, User, VideoAsset


class AdminAdvertisingApiTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser("ads-admin@example.com", "StrongPass123")
        self.device = AdminMFADevice.objects.create(
            user=self.admin,
            confirmed_at=timezone.now(),
        )
        login = self.client.post("/api/v1/admin/auth/login/", {
            "email": self.admin.email,
            "password": "StrongPass123",
            "otp": totp(self.device.secret),
            "device_id": "ads-admin-test",
        }, format="json")
        self.assertEqual(login.status_code, 200)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_admin_can_create_schedule_campaign_and_archive_it(self):
        starts = timezone.now() + timedelta(hours=1)
        ends = starts + timedelta(days=5)
        payload = {
            "name": "Campagne lancement",
            "advertiser": "Annonceur test",
            "status": "draft",
            "delivery_mode": "client_side",
            "formats": ["preroll", "midroll", "pause"],
            "media_url": "https://ads.example.test/creative.mp4",
            "image_url": "https://ads.example.test/pause.jpg",
            "media_duration_seconds": 20,
            "active_from": starts.isoformat(),
            "active_until": ends.isoformat(),
            "cue_points_seconds": [600, 1200],
            "target_countries": ["ci", "fr"],
            "contextual_genres": ["drame"],
            "interest_tags": ["familial"],
            "target_age_min": 18,
            "target_age_max": 65,
            "frequency_cap_per_day": 2,
        }
        created = self.client.post("/api/v1/admin/ad-campaigns/", payload, format="json")

        self.assertEqual(created.status_code, 201, created.data)
        self.assertEqual(created.data["target_countries"], ["CI", "FR"])
        self.assertEqual(created.data["cue_points_seconds"], [600, 1200])
        self.assertEqual(created.data["status"], "draft")

        activated = self.client.post(
            f"/api/v1/admin/ad-campaigns/{created.data['id']}/status/",
            {"status": "active"},
            format="json",
        )
        self.assertEqual(activated.status_code, 200)
        self.assertEqual(activated.data["status"], "active")

        archived = self.client.delete(f"/api/v1/admin/ad-campaigns/{created.data['id']}/")
        self.assertEqual(archived.status_code, 204)
        self.assertEqual(AdCampaign.objects.get(pk=created.data["id"]).status, "archived")

    def test_content_options_search_returns_ready_approved_movies_and_series(self):
        film = Content.objects.create(
            title="Film ciblé",
            type="movie",
            duration=105,
            producer_submission_status="approved",
        )
        series = Content.objects.create(
            title="Série ciblée",
            type="series",
            duration=45,
            producer_submission_status="approved",
        )
        for content, name in ((film, "film"), (series, "series")):
            VideoAsset.objects.create(
                content=content,
                hls_master_url=f"https://cdn.example.test/{name}/master.m3u8",
                dash_manifest_url=f"https://cdn.example.test/{name}/manifest.mpd",
                status="ready",
                moderation_status="approved",
                duration_seconds=content.duration * 60,
                published_at=timezone.now(),
            )
        pending = Content.objects.create(
            title="Film non approuvé",
            type="movie",
            producer_submission_status="pending",
        )
        VideoAsset.objects.create(
            content=pending,
            hls_master_url="https://cdn.example.test/pending/master.m3u8",
            dash_manifest_url="https://cdn.example.test/pending/manifest.mpd",
            status="ready",
            moderation_status="approved",
            published_at=timezone.now(),
        )

        response = self.client.get("/api/v1/admin/ad-campaigns/content-options/?search=Film")

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual([item["title"] for item in response.data], ["Film ciblé"])
        self.assertEqual(response.data[0]["type"], "movie")
        self.assertEqual(response.data[0]["duration_seconds"], 105 * 60)

        all_titles = self.client.get("/api/v1/admin/ad-campaigns/content-options/")
        self.assertEqual({item["title"] for item in all_titles.data}, {"Film ciblé", "Série ciblée"})

    def test_campaign_saves_midroll_positions_per_selected_title(self):
        content = Content.objects.create(
            title="Le film des repères",
            type="movie",
            duration=100,
            producer_submission_status="approved",
        )
        VideoAsset.objects.create(
            content=content,
            hls_master_url="https://cdn.example.test/cues/master.m3u8",
            dash_manifest_url="https://cdn.example.test/cues/manifest.mpd",
            status="ready",
            moderation_status="approved",
            duration_seconds=6000,
            published_at=timezone.now(),
        )
        payload = {
            "name": "Mid-roll ciblé",
            "status": "draft",
            "delivery_mode": "client_side",
            "formats": ["midroll"],
            "media_url": "https://ads.example.test/creative.mp4",
            "content_ids": [content.pk],
            "content_cue_points": {str(content.pk): [600, 1200]},
        }

        created = self.client.post("/api/v1/admin/ad-campaigns/", payload, format="json")

        self.assertEqual(created.status_code, 201, created.data)
        self.assertEqual(created.data["content_cue_points"], {str(content.pk): [600, 1200]})
        self.assertEqual(created.data["content_details"][0]["title"], "Le film des repères")
        self.assertEqual(created.data["content_details"][0]["duration_seconds"], 6000)

        payload["name"] = "Repères manquants"
        payload["content_cue_points"] = {}
        rejected = self.client.post("/api/v1/admin/ad-campaigns/", payload, format="json")
        self.assertEqual(rejected.status_code, 400)
        self.assertIn("content_cue_points", rejected.data)

    def test_ssai_pause_placement_is_rejected(self):
        response = self.client.post("/api/v1/admin/ad-campaigns/", {
            "name": "Pause non insérable",
            "delivery_mode": "ssai",
            "formats": ["pause"],
            "media_url": "https://ads.example.test/creative.mp4",
        }, format="json")

        self.assertEqual(response.status_code, 400)
        self.assertIn("formats", response.data)

    def test_platform_and_advertising_reports_return_dynamic_period_data(self):
        platform = self.client.get("/api/v1/admin/analytics/?days=7")
        ads = self.client.get("/api/v1/admin/advertising/analytics/?days=7")

        self.assertEqual(platform.status_code, 200, platform.data)
        self.assertEqual(ads.status_code, 200, ads.data)
        self.assertEqual(platform.data["period"]["from"], (timezone.localdate() - timedelta(days=6)).isoformat())
        self.assertEqual(len(platform.data["timeline"]), 7)
        self.assertIn("fill_rate_percent", ads.data["metrics"])
