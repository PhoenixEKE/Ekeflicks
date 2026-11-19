from django.conf import settings
from django.test import SimpleTestCase


class CorsSettingsTests(SimpleTestCase):
    def test_profile_header_is_allowed(self):
        self.assertIn('x-profile-id', settings.CORS_ALLOW_HEADERS)
