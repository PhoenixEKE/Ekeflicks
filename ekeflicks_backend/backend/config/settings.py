import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
PROJECT_DIR = BASE_DIR.parent

load_dotenv(PROJECT_DIR / '.env')

(BASE_DIR / 'logs').mkdir(exist_ok=True)


def env_bool(name, default=False):
    return os.environ.get(name, str(default)).strip().lower() in {'1', 'true', 'yes', 'on'}


def env_list(name, default=''):
    value = os.environ.get(name, default)
    return [item.strip() for item in value.split(',') if item.strip()]

# =========================================================
# SECURITY WARNING
# =========================================================

DEBUG = env_bool('DEBUG', False)

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = 'dev-only-change-me'
    else:
        raise RuntimeError('DJANGO_SECRET_KEY must be set when DEBUG=False')

ALLOWED_HOSTS = env_list(
    'ALLOWED_HOSTS',
    'localhost,127.0.0.1,ekeflicks.com,www.ekeflicks.com,api.ekeflicks.com'
)

# =========================================================
# APPLICATIONS
# =========================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.postgres',

    # Third-party
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'storages',
    'django_redis',
    'drf_yasg',

    # Local
    'core',
    'apps.auth.apps.AuthApiConfig',
    'apps.catalog.apps.CatalogConfig',
    'apps.profiles.apps.ProfilesConfig',
    'apps.playback.apps.PlaybackConfig',
    'apps.billing.apps.BillingConfig',
    'apps.notifications.apps.NotificationsConfig',
    'apps.recommendations.apps.RecommendationsConfig',
    'apps.analytics.apps.AnalyticsConfig',
    'apps.streaming.apps.StreamingConfig',
]

# =========================================================
# MIDDLEWARE
# =========================================================

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'apps.common.middleware.ApiContractMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

# =========================================================
# TEMPLATES
# =========================================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# =========================================================
# DATABASE
# =========================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME') or os.environ.get('POSTGRES_DB'),
        'USER': os.environ.get('DB_USER') or os.environ.get('POSTGRES_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD') or os.environ.get('POSTGRES_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'postgres'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': 60,
        'OPTIONS': {
            'connect_timeout': 10,
        }
    }
}

# =========================================================
# REDIS CACHE
# =========================================================

REDIS_HOST = os.environ.get('REDIS_HOST', 'redis')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': f'redis://{REDIS_HOST}:{REDIS_PORT}/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            #'PARSER_CLASS': 'redis.connection.HiredisParser',
            #'CONNECTION_POOL_CLASS': 'redis.BlockingConnectionPool',
            #'CONNECTION_POOL_CLASS_KWARGS': {
                #'max_connections': 50,
                #'timeout': 20,
            #},
            #'MAX_CONNECTIONS': 1000,
            #'PICKLE_VERSION': -1,
        },
        'KEY_PREFIX': 'ekeflicks',
        'TIMEOUT': 300,
    }
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

# =========================================================
# PASSWORD VALIDATION
# =========================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {
            'min_length': 8,
        }
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# =========================================================
# INTERNATIONALIZATION
# =========================================================

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Europe/Paris'

USE_I18N = True
USE_TZ = True

# =========================================================
# STATIC / MEDIA - Separes pour stabilite
# =========================================================

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# =========================================================
# AUTH USER
# =========================================================

AUTH_USER_MODEL = 'core.User'

# =========================================================
# REST FRAMEWORK
# =========================================================

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'apps.common.pagination.ApiPageNumberPagination',
    'PAGE_SIZE': 20,
    'EXCEPTION_HANDLER': 'apps.common.exceptions.api_exception_handler',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.UserRateThrottle',
        'rest_framework.throttling.AnonRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'user': '1000/day',
        'anon': '100/day',
        'login': '5/minute',
    },
}

SWAGGER_SETTINGS = {
    'DEFAULT_INFO': 'config.schema.API_INFO',
    'SECURITY_DEFINITIONS': {
        'Bearer': {'type': 'apiKey', 'name': 'Authorization', 'in': 'header'},
    },
}

# =========================================================
# JWT
# =========================================================

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

# =========================================================
# STREAMING
# =========================================================

STREAMING_REQUIRE_ACTIVE_SUBSCRIPTION = env_bool('STREAMING_REQUIRE_ACTIVE_SUBSCRIPTION', True)
STREAMING_MANIFEST_TTL_SECONDS = int(os.environ.get('STREAMING_MANIFEST_TTL_SECONDS', '3600'))
HLS_SEGMENT_DURATION_SECONDS = int(os.environ.get('HLS_SEGMENT_DURATION_SECONDS', '6'))
OFFLINE_LICENSE_DAYS = int(os.environ.get('OFFLINE_LICENSE_DAYS', '30'))
STREAMING_CDN_BASE_URL = os.environ.get('STREAMING_CDN_BASE_URL', '')
STREAMING_STORE_PROCESSING_ARTIFACTS = env_bool('STREAMING_STORE_PROCESSING_ARTIFACTS', True)
STREAMING_SIGNED_URLS_ENABLED = env_bool('STREAMING_SIGNED_URLS_ENABLED', True)
STREAMING_SIGNED_URL_TTL_SECONDS = int(os.environ.get('STREAMING_SIGNED_URL_TTL_SECONDS', STREAMING_MANIFEST_TTL_SECONDS))
STREAMING_SIGNING_SECRET = os.environ.get('STREAMING_SIGNING_SECRET') or SECRET_KEY
MEDIA_CDN_BASE_URL = os.environ.get('MEDIA_CDN_BASE_URL', STREAMING_CDN_BASE_URL)

DRM_LICENSE_TTL_SECONDS = int(os.environ.get('DRM_LICENSE_TTL_SECONDS', '3600'))
DRM_MASTER_KEY = os.environ.get('DRM_MASTER_KEY') or SECRET_KEY
DRM_WIDEVINE_LICENSE_URL = os.environ.get('DRM_WIDEVINE_LICENSE_URL', '')
DRM_FAIRPLAY_LICENSE_URL = os.environ.get('DRM_FAIRPLAY_LICENSE_URL', '')
DRM_FAIRPLAY_CERTIFICATE_URL = os.environ.get('DRM_FAIRPLAY_CERTIFICATE_URL', '')
DRM_PLAYREADY_LICENSE_URL = os.environ.get('DRM_PLAYREADY_LICENSE_URL', '')
DRM_ANDROID_OFFLINE_LICENSE_DAYS = int(os.environ.get('DRM_ANDROID_OFFLINE_LICENSE_DAYS', OFFLINE_LICENSE_DAYS))
DRM_IOS_OFFLINE_LICENSE_DAYS = int(os.environ.get('DRM_IOS_OFFLINE_LICENSE_DAYS', OFFLINE_LICENSE_DAYS))
AXINOM_DRM_ENABLED = env_bool('AXINOM_DRM_ENABLED', False)
AXINOM_TENANT_ID = os.environ.get('AXINOM_TENANT_ID', '')
AXINOM_POLICY_ID = os.environ.get('AXINOM_POLICY_ID', '')
AXINOM_COMMUNICATION_KEY_ID = os.environ.get('AXINOM_COMMUNICATION_KEY_ID', '')
AXINOM_COMMUNICATION_KEY = os.environ.get('AXINOM_COMMUNICATION_KEY', '')
AXINOM_WIDEVINE_LICENSE_URL = os.environ.get('AXINOM_WIDEVINE_LICENSE_URL', '')
AXINOM_FAIRPLAY_LICENSE_URL = os.environ.get('AXINOM_FAIRPLAY_LICENSE_URL', '')
AXINOM_FAIRPLAY_CERTIFICATE_URL = os.environ.get('AXINOM_FAIRPLAY_CERTIFICATE_URL', '')
AXINOM_PLAYREADY_LICENSE_URL = os.environ.get('AXINOM_PLAYREADY_LICENSE_URL', '')

# =========================================================
# PAYMENT PROVIDERS
# =========================================================

PAYMENT_RETURN_URL = os.environ.get('PAYMENT_RETURN_URL', 'https://ekeflicks.com/payment/return')
PAYMENT_NOTIFY_URL = os.environ.get('PAYMENT_NOTIFY_URL', 'https://api.ekeflicks.com/api/v1/billing/webhooks')

CINETPAY_API_KEY = os.environ.get('CINETPAY_API_KEY', '')
CINETPAY_SITE_ID = os.environ.get('CINETPAY_SITE_ID', '')
CINETPAY_WEBHOOK_SECRET = os.environ.get('CINETPAY_WEBHOOK_SECRET', '')

PAYSTACK_SECRET_KEY = os.environ.get('PAYSTACK_SECRET_KEY', '')

FLUTTERWAVE_SECRET_KEY = os.environ.get('FLUTTERWAVE_SECRET_KEY', '')
FLUTTERWAVE_WEBHOOK_SECRET = os.environ.get('FLUTTERWAVE_WEBHOOK_SECRET', '')

WAVE_API_KEY = os.environ.get('WAVE_API_KEY', '')
WAVE_WEBHOOK_SECRET = os.environ.get('WAVE_WEBHOOK_SECRET', '')

# =========================================================
# RECOMMENDATION ENGINE / NEO4J
# =========================================================

RECOMMENDATION_ENGINE = os.environ.get('RECOMMENDATION_ENGINE', 'django').lower()
RECOMMENDATION_DEFAULT_LIMIT = int(os.environ.get('RECOMMENDATION_DEFAULT_LIMIT', '20'))

NEO4J_ENABLED = env_bool('NEO4J_ENABLED', False)
NEO4J_URI = os.environ.get('NEO4J_URI', 'bolt://neo4j:7687')
NEO4J_USERNAME = os.environ.get('NEO4J_USERNAME', 'neo4j')
NEO4J_PASSWORD = os.environ.get('NEO4J_PASSWORD', '')
NEO4J_DATABASE = os.environ.get('NEO4J_DATABASE', 'neo4j')

# =========================================================
# CORS
# =========================================================

CORS_ALLOW_ALL_ORIGINS = False

CORS_ALLOWED_ORIGINS = [
    'https://ekeflicks.com',
    'https://api.ekeflicks.com',
    'https://www.ekeflicks.com',
    'http://localhost:3000',
    'http://localhost:8080',
    'http://192.162.68.247:8080',
]

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# =========================================================
# STORAGE - MinIO internal / Backblaze B2 final
# =========================================================

USE_B2_STORAGE = env_bool("USE_B2_STORAGE", False)
USE_B2_FINAL_STORAGE = env_bool("USE_B2_FINAL_STORAGE", USE_B2_STORAGE)

MINIO_ACCESS_KEY = os.environ.get("MINIO_ACCESS_KEY")
MINIO_SECRET_KEY = os.environ.get("MINIO_SECRET_KEY")
MINIO_BUCKET = os.environ.get("MINIO_BUCKET") or "ekeflicks-temp"
MINIO_ENDPOINT = os.environ.get("MINIO_ENDPOINT")
MINIO_USE_SSL = env_bool("MINIO_USE_SSL", False)
MINIO_REGION = os.environ.get("MINIO_REGION", "us-east-1")

B2_KEY_ID = os.environ.get("B2_KEY_ID")
B2_APPLICATION_KEY = os.environ.get("B2_APPLICATION_KEY")
B2_BUCKET = os.environ.get("B2_BUCKET") or "ekeflicks-videos"
B2_ENDPOINT = os.environ.get("B2_ENDPOINT")
B2_REGION = os.environ.get("B2_REGION", "us-west-005")
B2_VIDEO_BUCKET = os.environ.get("B2_VIDEO_BUCKET") or B2_BUCKET
B2_POSTER_BUCKET = os.environ.get("B2_POSTER_BUCKET") or "ekeflicks-posters"
B2_BACKDROP_BUCKET = os.environ.get("B2_BACKDROP_BUCKET") or "ekeflicks-backdrops"
B2_TRAILER_BUCKET = os.environ.get("B2_TRAILER_BUCKET") or "ekeflicks-trailers"
B2_AVATAR_BUCKET = os.environ.get("B2_AVATAR_BUCKET") or "ekeflicks-avatars"
B2_SUBTITLE_BUCKET = os.environ.get("B2_SUBTITLE_BUCKET") or "ekeflicks-subtitles"

AWS_ACCESS_KEY_ID = MINIO_ACCESS_KEY
AWS_SECRET_ACCESS_KEY = MINIO_SECRET_KEY
AWS_STORAGE_BUCKET_NAME = MINIO_BUCKET
AWS_S3_ENDPOINT_URL = MINIO_ENDPOINT.rstrip("/") if MINIO_ENDPOINT else None
AWS_S3_REGION_NAME = MINIO_REGION
AWS_S3_USE_SSL = MINIO_USE_SSL
AWS_S3_VERIFY = False
AWS_S3_ADDRESSING_STYLE = "path"
AWS_S3_SIGNATURE_VERSION = "s3v4"
AWS_DEFAULT_ACL = None
AWS_QUERYSTRING_AUTH = False
AWS_S3_FILE_OVERWRITE = True

MINIO_STORAGE_OPTIONS = {
    "access_key": MINIO_ACCESS_KEY,
    "secret_key": MINIO_SECRET_KEY,
    "bucket_name": MINIO_BUCKET,
    "endpoint_url": AWS_S3_ENDPOINT_URL,
    "region_name": MINIO_REGION,
    "use_ssl": MINIO_USE_SSL,
    "verify": False,
    "addressing_style": "path",
    "signature_version": "s3v4",
    "default_acl": None,
    "querystring_auth": False,
    "file_overwrite": True,
}

B2_STORAGE_OPTIONS = {
    "access_key": B2_KEY_ID,
    "secret_key": B2_APPLICATION_KEY,
    "bucket_name": B2_BUCKET,
    "endpoint_url": B2_ENDPOINT,
    "region_name": B2_REGION,
    "default_acl": None,
    "querystring_auth": False,
    "file_overwrite": True,
    "verify": True,
}


def b2_storage_options(bucket_name):
    return {
        **B2_STORAGE_OPTIONS,
        "bucket_name": bucket_name,
    }

# Storage backends. Default is internal MinIO. Final media can target B2.
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
        "OPTIONS": MINIO_STORAGE_OPTIONS,
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}

if USE_B2_FINAL_STORAGE:
    for storage_alias, bucket_name in {
        "final_videos": B2_VIDEO_BUCKET,
        "final_posters": B2_POSTER_BUCKET,
        "final_backdrops": B2_BACKDROP_BUCKET,
        "final_trailers": B2_TRAILER_BUCKET,
        "final_avatars": B2_AVATAR_BUCKET,
        "final_subtitles": B2_SUBTITLE_BUCKET,
    }.items():
        STORAGES[storage_alias] = {
            "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
            "OPTIONS": b2_storage_options(bucket_name),
        }
    STORAGES["final_media"] = STORAGES["final_videos"]
else:
    for storage_alias in [
        "final_videos",
        "final_posters",
        "final_backdrops",
        "final_trailers",
        "final_avatars",
        "final_subtitles",
        "final_media",
    ]:
        STORAGES[storage_alias] = STORAGES["default"]

# =========================================================
# CELERY
# =========================================================

CELERY_BROKER_URL = f'redis://{REDIS_HOST}:{REDIS_PORT}/0'
CELERY_RESULT_BACKEND = f'redis://{REDIS_HOST}:{REDIS_PORT}/0'

CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 30 * 60

# =========================================================
# SECURITY - Production
# =========================================================

if not DEBUG:
    # SSL / HTTPS
    SECURE_SSL_REDIRECT = False
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    USE_X_FORWARDED_HOST = True

    # Cookies
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SESSION_COOKIE_SAMESITE = "Lax"
    CSRF_COOKIE_SAMESITE = "Lax"

    # Headers
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'

    # HSTS (1 an)
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True

# =========================================================
# API
# =========================================================

API_VERSION = os.environ.get('API_VERSION', 'v1')
API_BASE_URL = os.environ.get('API_BASE_URL', 'https://api.ekeflicks.com')
FRONTEND_BASE_URL = os.environ.get('FRONTEND_BASE_URL', 'https://ekeflicks.com')
EMAIL_VERIFICATION_FRONTEND_PATH = os.environ.get('EMAIL_VERIFICATION_FRONTEND_PATH', '/verify-email')
PASSWORD_RESET_FRONTEND_PATH = os.environ.get('PASSWORD_RESET_FRONTEND_PATH', '/reset-password')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@ekeflicks.com')
ACCOUNT_CLOSURE_GRACE_DAYS = int(os.environ.get('ACCOUNT_CLOSURE_GRACE_DAYS', 7))
EMAIL_VERIFICATION_TOKEN_TTL_HOURS = int(os.environ.get('EMAIL_VERIFICATION_TOKEN_TTL_HOURS', 24))
PASSWORD_RESET_TOKEN_TTL_MINUTES = int(os.environ.get('PASSWORD_RESET_TOKEN_TTL_MINUTES', 30))

EMAIL_HOST = os.environ.get('EMAIL_HOST', '')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
EMAIL_USE_TLS = env_bool('EMAIL_USE_TLS', True)
EMAIL_BACKEND = (
    'django.core.mail.backends.smtp.EmailBackend'
    if EMAIL_HOST
    else 'django.core.mail.backends.console.EmailBackend'
)

# =========================================================
# CLICKHOUSE
# =========================================================

CLICKHOUSE_HOST = os.environ.get('CLICKHOUSE_HOST')
CLICKHOUSE_PORT = int(os.environ.get('CLICKHOUSE_PORT', 8123))
CLICKHOUSE_USER = os.environ.get('CLICKHOUSE_USER')
CLICKHOUSE_PASSWORD = os.environ.get('CLICKHOUSE_PASSWORD')

# =========================================================
# LOGGING - Production ready
# =========================================================

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {asctime} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose' if DEBUG else 'simple',
        },
        'file': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': BASE_DIR / 'logs' / 'ekeflicks.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'] if not DEBUG else ['console'],
        'level': 'DEBUG' if DEBUG else 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG' if DEBUG else 'ERROR',
            'propagate': False,
        },
        'core': {
            'handlers': ['console', 'file'],
            'level': 'DEBUG' if DEBUG else 'INFO',
            'propagate': False,
        },
    },
}
