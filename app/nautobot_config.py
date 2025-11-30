import os
from pathlib import Path
from django.core.exceptions import ImproperlyConfigured
from nautobot.core.settings import *  # noqa

# ---------------------------
# Helpers
# ---------------------------
def env(name, default=None, required=False):
    v = os.environ.get(name, default)
    if required and v is None:
        raise ImproperlyConfigured(f"Missing required env: {name}")
    return v

# ---------------------------
# Core
# ---------------------------
SECRET_KEY = env("SECRET_KEY", required=True)
ALLOWED_HOSTS = [h.strip() for h in env("ALLOWED_HOSTS", "*").split(",")]
DEBUG = env("DEBUG", "False").lower() in ("1", "true", "yes", "on")

ROOT_URLCONF = "nautobot.core.urls"
WSGI_APPLICATION = "nautobot.core.wsgi.application"

# Security (Cloud Run/Proxy)
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# ---------------------------
# Paths (local fallback; Cloud Run ephemeral)
# ---------------------------
DATA_DIR = Path(env("DATA_DIR", "/opt/nautobot"))
STATIC_ROOT = env("STATIC_ROOT", str(DATA_DIR / "static"))
MEDIA_ROOT = env("MEDIA_ROOT", str(DATA_DIR / "media"))
for d in (STATIC_ROOT, MEDIA_ROOT):
    os.makedirs(d, exist_ok=True)

# ---------------------------
# Database (PostgreSQL)
# ---------------------------
DB_NAME = env("DB_NAME", required=True)
DB_USER = env("DB_USER", required=True)
DB_PASSWORD = env("DB_PASSWORD", required=True)
DB_HOST = env("DB_HOST", required=True)    # private IP or /cloudsql/INSTANCE for proxy
DB_PORT = env("DB_PORT", "5432")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": DB_NAME,
        "USER": DB_USER,
        "PASSWORD": DB_PASSWORD,
        "HOST": DB_HOST,
        "PORT": DB_PORT,
        "CONN_MAX_AGE": int(env("DB_CONN_MAX_AGE", "60")),
    }
}

# ---------------------------
# Redis / Celery
# ---------------------------
REDIS_HOST = env("REDIS_HOST", required=True)
REDIS_PORT = env("REDIS_PORT", "6379")
REDIS_DB   = env("REDIS_DB", "0")
REDIS_PASSWORD = env("REDIS_PASSWORD", "")
_auth = f":{REDIS_PASSWORD}@" if REDIS_PASSWORD else ""
REDIS_URL = f"redis://{_auth}{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"

CELERY_BROKER_URL = REDIS_URL

# Separate cache DB (recommended)
CACHE_REDIS_DB = env("CACHE_REDIS_DB", "1")
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": f"redis://{_auth}{REDIS_HOST}:{REDIS_PORT}/{CACHE_REDIS_DB}",
        "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
    }
}

# ---------------------------
# GCS Storage (NO signed URLs)
# ---------------------------
USE_GCS_STATIC = bool(env("GCS_STATIC_BUCKET"))
USE_GCS_MEDIA  = bool(env("GCS_MEDIA_BUCKET"))

# IMPORTANT: prevent signed URLs (which need a private key)
GS_QUERYSTRING_AUTH = False
GS_DEFAULT_ACL = None

if USE_GCS_STATIC or USE_GCS_MEDIA:
    # Custom storage classes to allow different buckets/prefixes
    from storages.backends.gcloud import GoogleCloudStorage

    class StaticRootGCS(GoogleCloudStorage):
        bucket_name = env("GCS_STATIC_BUCKET", required=True)
        location = env("GS_STATIC_LOCATION", "static")  # objects live under gs://bucket/static/
        default_acl = None

    class MediaRootGCS(GoogleCloudStorage):
        bucket_name = env("GCS_MEDIA_BUCKET", required=True)
        location = env("GS_MEDIA_LOCATION", "media")    # objects live under gs://bucket/media/
        default_acl = None

# Static files
if USE_GCS_STATIC:
    STATICFILES_STORAGE = "nautobot_config.StaticRootGCS"
    STATIC_URL = f"https://storage.googleapis.com/{env('GCS_STATIC_BUCKET')}/{env('GS_STATIC_LOCATION','static')}/"
else:
    STATIC_URL = "/static/"
    # WhiteNoise only when serving local static
    MIDDLEWARE = ["whitenoise.middleware.WhiteNoiseMiddleware", *MIDDLEWARE]
    # Optional for dev ergonomics
    WHITENOISE_MANIFEST_STRICT = False

# Media files
if USE_GCS_MEDIA:
    DEFAULT_FILE_STORAGE = "nautobot_config.MediaRootGCS"
    MEDIA_URL = f"https://storage.googleapis.com/{env('GCS_MEDIA_BUCKET')}/{env('GS_MEDIA_LOCATION','media')}/"
else:
    MEDIA_URL = "/media/"

# ---------------------------
# Auth backends
# ---------------------------
AUTHENTICATION_BACKENDS = [
    "nautobot.core.authentication.ObjectPermissionBackend",
    "django.contrib.auth.backends.ModelBackend",
]

# Logging (optional but recommended)
LOG_LEVEL = os.getenv("NAUTOBOT_LOG_LEVEL", "INFO")

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": LOG_LEVEL,
    },
}