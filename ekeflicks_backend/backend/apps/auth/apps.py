from django.apps import AppConfig


class AuthApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.auth'
    label = 'ekeflicks_auth'
    verbose_name = 'EkeFlicks Auth API'
