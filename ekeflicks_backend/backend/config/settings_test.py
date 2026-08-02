"""Deterministic settings used by local and CI test runs.

Only PostgreSQL is kept as an infrastructure dependency because the schema uses
PostgreSQL-specific search fields and indexes.  Cache, sessions, email, Celery
and media storage are deliberately process-local.
"""

import os

os.environ.setdefault('DJANGO_SECRET_KEY', 'ekeflicks-test-key-not-for-production')

from .settings import *  # noqa: E402,F401,F403

DEBUG = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB', 'ekeflicks_test'),
        'USER': os.environ.get('POSTGRES_USER', 'ekeflicks'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD', 'ekeflicks'),
        'HOST': os.environ.get('POSTGRES_HOST', '127.0.0.1'),
        'PORT': os.environ.get('POSTGRES_PORT', '5432'),
        'CONN_MAX_AGE': 0,
    },
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'ekeflicks-tests',
    },
}
SESSION_ENGINE = 'django.contrib.sessions.backends.db'

PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',
]

EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

MEDIA_ROOT = BASE_DIR / 'test_media'

try:
    del DEFAULT_FILE_STORAGE
except NameError:
    pass

try:
    del STATICFILES_STORAGE
except NameError:
    pass

STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
    },
    'final_media': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_videos': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_posters': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_backdrops': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_trailers': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_avatars': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_subtitles': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
}

CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
CELERY_BROKER_URL = 'memory://'
CELERY_RESULT_BACKEND = 'cache+memory://'

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
}
