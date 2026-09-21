from io import BytesIO

from django.contrib import admin
from django.contrib.auth import get_user_model
from django.test import RequestFactory, TestCase
from django.urls import reverse
from django.utils import timezone
from pypdf import PdfReader
from rest_framework.test import APIClient

from core.admin import TechnicalSpecificationAdmin
from core.models import TechnicalSpecification


User = get_user_model()


class TechnicalSpecificationApiTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="technical-spec@example.com",
            password="StrongPassword123!",
            is_producer=True,
        )

        self.client = APIClient()
        self.client.force_authenticate(
            user=self.user,
        )

    def _create_spec(
        self,
        *,
        version="1.0",
        published=True,
        published_at=None,
    ):
        return TechnicalSpecification.objects.create(
            title=(
                "Cahier des charges technique "
                "EKEFLICKS"
            ),
            version=version,
            introduction=(
                "Specifications techniques "
                "des livraisons."
            ),
            sections=[
                {
                    "title": "Poster",
                    "description": (
                        "Affiche verticale."
                    ),
                    "items": [
                        {
                            "label": "Ratio",
                            "value": "2:3",
                        },
                        {
                            "label": (
                                "Resolution minimale"
                            ),
                            "value": (
                                "1000 x 1500 pixels"
                            ),
                        },
                    ],
                }
            ],
            is_published=published,
            published_at=(
                published_at
                if published
                else None
            ),
        )

    def test_requires_authentication(self):
        anonymous = APIClient()

        response = anonymous.get(
            reverse(
                "technical-specification"
            )
        )

        self.assertIn(
            response.status_code,
            (401, 403),
        )

    def test_returns_404_without_published_specification(
        self,
    ):
        self._create_spec(
            published=False,
        )

        response = self.client.get(
            reverse(
                "technical-specification"
            )
        )

        self.assertEqual(
            response.status_code,
            404,
        )

    def test_returns_published_specification(
        self,
    ):
        specification = self._create_spec(
            published_at=timezone.now(),
        )

        response = self.client.get(
            reverse(
                "technical-specification"
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data["id"],
            str(specification.id),
        )

        self.assertEqual(
            response.data["version"],
            "1.0",
        )

        self.assertEqual(
            response.data["sections"][0]["title"],
            "Poster",
        )

    def test_latest_published_specification_is_used(
        self,
    ):
        older = timezone.now() - timezone.timedelta(
            days=1
        )
        newer = timezone.now()

        self._create_spec(
            version="1.0",
            published_at=older,
        )

        self._create_spec(
            version="1.1",
            published_at=newer,
        )

        response = self.client.get(
            reverse(
                "technical-specification"
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data["version"],
            "1.1",
        )

    def test_pdf_download_is_valid_pdf(
        self,
    ):
        self._create_spec(
            published_at=timezone.now(),
        )

        response = self.client.get(
            reverse(
                "technical-specification-pdf"
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response["Content-Type"],
            "application/pdf",
        )

        self.assertIn(
            "attachment;",
            response["Content-Disposition"],
        )

        pdf_bytes = b"".join(
            response.streaming_content
        )

        self.assertTrue(
            pdf_bytes.startswith(b"%PDF")
        )

        reader = PdfReader(
            BytesIO(pdf_bytes)
        )

        self.assertGreaterEqual(
            len(reader.pages),
            1,
        )


class TechnicalSpecificationAdminTests(
    TestCase
):
    def setUp(self):
        self.admin_user = (
            User.objects.create_superuser(
                email="admin-spec@example.com",
                password="StrongPassword123!",
            )
        )

        self.factory = RequestFactory()

        self.model_admin = (
            TechnicalSpecificationAdmin(
                TechnicalSpecification,
                admin.site,
            )
        )

    def test_publishing_new_version_unpublishes_old_version(
        self,
    ):
        old_specification = (
            TechnicalSpecification.objects.create(
                version="1.0",
                is_published=True,
                published_at=timezone.now(),
            )
        )

        new_specification = (
            TechnicalSpecification(
                version="1.1",
                is_published=True,
            )
        )

        request = self.factory.post(
            "/admin/core/"
            "technicalspecification/add/"
        )
        request.user = self.admin_user

        self.model_admin.save_model(
            request,
            new_specification,
            form=None,
            change=False,
        )

        old_specification.refresh_from_db()
        new_specification.refresh_from_db()

        self.assertFalse(
            old_specification.is_published
        )

        self.assertTrue(
            new_specification.is_published
        )

        self.assertIsNotNone(
            new_specification.published_at
        )

        self.assertEqual(
            TechnicalSpecification.objects.filter(
                is_published=True,
            ).count(),
            1,
        )
