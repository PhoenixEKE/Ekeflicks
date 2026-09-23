from django.contrib.auth import get_user_model
from django.urls import reverse

from rest_framework import status
from rest_framework.exceptions import (
    PermissionDenied,
    ValidationError,
)
from rest_framework.test import APITestCase

from apps.salons.icebreakers import (
    MAX_ICEBREAKERS,
    SALON_FACILITATION_VERSION,
    build_salon_icebreakers,
)
from apps.salons.models import Salon
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
)
from core.models import Content


User = get_user_model()


class SalonIcebreakerTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="g53l-host@example.com",
            password="test-pass-123",
        )

        self.member = User.objects.create_user(
            email="g53l-member@example.com",
            password="test-pass-123",
        )

        self.outsider = User.objects.create_user(
            email="g53l-outsider@example.com",
            password="test-pass-123",
        )

        self.content = Content.objects.create(
            title="G5-3L Film Test",
            producer_submission_status="approved",
        )

        self.salon = create_salon(
            host=self.host,
            name="G5-3L Salon",
            content=self.content,
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=10,
        )

        join_salon(
            salon=self.salon,
            user=self.member,
        )

    def _url(self):
        return reverse(
            "salon-icebreakers",
            kwargs={
                "pk": self.salon.pk,
            },
        )

    def test_version(self):
        result = build_salon_icebreakers(
            salon=self.salon,
            user=self.host,
        )

        self.assertEqual(
            result.version,
            "g5_3l_v1",
        )

        self.assertEqual(
            result.version,
            SALON_FACILITATION_VERSION,
        )

    def test_content_context_is_used(self):
        result = build_salon_icebreakers(
            salon=self.salon,
            user=self.host,
        )

        self.assertEqual(
            result.context_level,
            "content",
        )

        self.assertTrue(
            any(
                self.content.title
                in item.text
                for item
                in result.icebreakers
            )
        )

    def test_fallback_without_content(self):
        salon = create_salon(
            host=self.host,
            name="G5-3L Empty Context",
            content=None,
            visibility=Salon.VISIBILITY_PRIVATE,
        )

        result = build_salon_icebreakers(
            salon=salon,
            user=self.host,
        )

        self.assertEqual(
            result.context_level,
            "salon",
        )

        self.assertGreater(
            len(result.icebreakers),
            0,
        )

    def test_deterministic(self):
        first = build_salon_icebreakers(
            salon=self.salon,
            user=self.member,
        )

        second = build_salon_icebreakers(
            salon=self.salon,
            user=self.member,
        )

        self.assertEqual(
            first,
            second,
        )

    def test_result_limit(self):
        result = build_salon_icebreakers(
            salon=self.salon,
            user=self.member,
        )

        self.assertLessEqual(
            len(result.icebreakers),
            MAX_ICEBREAKERS,
        )

        self.assertEqual(
            len(result.icebreakers),
            4,
        )

    def test_outsider_service_forbidden(self):
        with self.assertRaises(
            PermissionDenied
        ):
            build_salon_icebreakers(
                salon=self.salon,
                user=self.outsider,
            )

    def test_closed_salon_service_rejected(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        self.salon.refresh_from_db()

        with self.assertRaises(
            ValidationError
        ):
            build_salon_icebreakers(
                salon=self.salon,
                user=self.host,
            )

    def test_api_requires_authentication(self):
        response = self.client.get(
            self._url()
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_active_member_can_request(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.get(
            self._url()
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data["salon_id"],
            str(self.salon.pk),
        )

        self.assertEqual(
            response.data["version"],
            SALON_FACILITATION_VERSION,
        )

        self.assertEqual(
            response.data["context_level"],
            "content",
        )

        self.assertEqual(
            len(response.data["icebreakers"]),
            4,
        )

    def test_authenticated_outsider_is_forbidden(self):
        self.client.force_authenticate(
            user=self.outsider,
        )

        response = self.client.get(
            self._url()
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_api_contract_has_only_public_fields(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.get(
            self._url()
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            set(response.data.keys()),
            {
                "salon_id",
                "version",
                "context_level",
                "icebreakers",
            },
        )

        for item in response.data[
            "icebreakers"
        ]:
            self.assertEqual(
                set(item.keys()),
                {
                    "id",
                    "text",
                    "kind",
                },
            )

    def test_api_does_not_expose_user_private_data(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.get(
            self._url()
        )

        body = str(response.data).lower()

        for forbidden in (
            self.host.email.lower(),
            self.member.email.lower(),
            self.outsider.email.lower(),
            "password",
            "phone",
            "country_code",
            "common_content_ids",
            "common_genre_slugs",
        ):
            self.assertNotIn(
                forbidden,
                body,
            )
