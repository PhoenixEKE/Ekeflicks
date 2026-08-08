from unittest.mock import Mock, patch

from django.test import SimpleTestCase


class AvatarApiTests(SimpleTestCase):
    def test_avatar_endpoint_is_public_and_lists_supported_images(self):
        storage = Mock()
        storage.listdir.side_effect = lambda directory: {
            '': (['children'], ['adult.png', 'notes.txt']),
            'children': ([], ['child.WEBP']),
        }[directory]
        storage.url.side_effect = lambda path: f'https://cdn.example.test/{path}'

        with patch(
            'apps.common.avatar_views.storages',
            {'final_avatars': storage},
        ):
            response = self.client.get('/api/v1/avatars/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'avatars': [
                    {
                        'name': 'adult',
                        'path': 'adult.png',
                        'url': 'https://cdn.example.test/adult.png',
                    },
                    {
                        'name': 'child',
                        'path': 'children/child.WEBP',
                        'url': 'https://cdn.example.test/children/child.WEBP',
                    },
                ]
            },
        )
        storage.url.assert_any_call('adult.png')
        storage.url.assert_any_call('children/child.WEBP')

    def test_avatar_upload_requires_authentication(self):
        response = self.client.post('/api/v1/avatars/')

        self.assertEqual(response.status_code, 401)
