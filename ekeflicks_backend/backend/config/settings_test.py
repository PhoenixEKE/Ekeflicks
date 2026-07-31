from .settings import *  # noqa: F401,F403

DEBUG = True

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
