locals {
  image = "${var.region}-docker.pkg.dev/${var.project_id}/nautobot/nautobot:${var.image_tag}"

  NAUTOBOT_UWSGI_HTTP = "0.0.0.0:8080"
  # Environment variables shared by ALL Cloud Run Jobs
  base_common_env = {
    ALLOWED_HOSTS = "*"
    DEBUG         = "True"

    DB_NAME     = "nautobot"
    DB_USER     = "nautobot"
    DB_PASSWORD = random_password.db.result
    DB_HOST     = "${google_sql_database_instance.pg.private_ip_address}"
    DB_PORT     = 5432

    REDIS_HOST     = "${google_redis_instance.redis.host}"
    REDIS_PORT     = 6379
    REDIS_DB       = 0
    REDIS_PASSWORD = ""

    DATA_DIR    = "/tmp/nautobot"
    STATIC_ROOT = "/tmp/nautobot/static"
    MEDIA_ROOT  = "/tmp/nautobot/media"
    GIT_ROOT    = "/tmp/nautobot/git"
    JOBS_ROOT   = "/tmp/nautobot/jobs"

    STORAGE_BACKEND  = "storages.backends.gcloud.GoogleCloudStorage"
    METRICS_ENABLED  = "False"
    MAINTENANCE_MODE = false

    GCS_MEDIA_BUCKET           = "${google_storage_bucket.media.name}"
    GCS_STATIC_BUCKET          = "${google_storage_bucket.static.name}"
    WHITENOISE_MANIFEST_STRICT = false
  }

  service_extra_env = {
    DISABLE_REDIS                             = "False"
    DJANGO_SETTINGS_MODULE                    = "nautobot_config"
    NAUTOBOT_CONFIG                           = "/opt/nautobot/nautobot_config.py"
    CELERY_TASK_TRACK_STARTED                 = "true"
    CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = "true"
  }

  # Special env used only in collectstatic
  job_collectstatic_extra_env = {
    STATIC_URL                 = "https://storage.googleapis.com/${google_storage_bucket.static.name}/static/"
    MEDIA_URL                  = "https://storage.googleapis.com/${google_storage_bucket.static.name}/"
    WHITENOISE_MANIFEST_STRICT = false
  }

  # Special env used only in createsuperuser
  job_superuser_extra_env = {
    DJANGO_SUPERUSER_USERNAME = "admin"
    DJANGO_SUPERUSER_EMAIL    = "admin@example.com"
    DJANGO_SUPERUSER_PASSWORD = "ChangeMe#12345"
  }
}
