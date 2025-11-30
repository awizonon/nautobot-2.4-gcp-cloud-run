resource "google_cloud_run_v2_job" "migrate" {
  name                = "cloud-run-job-migrate"
  location            = var.region
  deletion_protection = false
  template {
    template {
      service_account = google_service_account.web.email
      containers {
        image   = local.image
        command = ["nautobot-server", "migrate", "--noinput"]
        env {
          name = "SECRET_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret_version.secret_key_v.secret
              version = "1"
            }
          }
        }

        dynamic "env" {
          for_each = local.base_common_env
          content {
            name  = env.key
            value = env.value
          }
        }

      }
      vpc_access {
        connector = google_vpc_access_connector.run.id
        egress    = "ALL_TRAFFIC"
      }
      max_retries = 1
    }
  }
}

resource "google_cloud_run_v2_job" "collectstatic" {
  name                = "cloud-run-job-collectstatic"
  location            = var.region
  deletion_protection = false
  template {
    template {
      service_account = google_service_account.web.email
      containers {
        image   = local.image
        command = ["nautobot-server", "collectstatic", "--noinput"]
        env {
          name = "SECRET_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret_version.secret_key_v.secret
              version = "1"
            }
          }
        }
        env {
          name  = "STATIC_URL"
          value = local.job_collectstatic_extra_env.STATIC_URL
        }
        env {
          name  = "MEDIA_URL"
          value = local.job_collectstatic_extra_env.MEDIA_URL
        }
        env {
          name  = "WHITENOISE_MANIFEST_STRICT"
          value = local.job_collectstatic_extra_env.WHITENOISE_MANIFEST_STRICT
        }

        dynamic "env" {
          for_each = local.base_common_env
          content {
            name  = env.key
            value = env.value
          }
        }

      }
      vpc_access {
        connector = google_vpc_access_connector.run.id
        egress    = "ALL_TRAFFIC"
      }
    }
  }
  depends_on = [google_cloud_run_v2_job.migrate]
}

resource "google_cloud_run_v2_job" "createsuperuser" {
  name                = "cloud-run-job-createsuperuser"
  location            = var.region
  deletion_protection = false
  template {
    template {
      service_account = google_service_account.web.email
      containers {
        image = local.image
        args  = ["bash", "-lc", "echo \"from django.contrib.auth import get_user_model; u=get_user_model(); u.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists() or u.objects.create_superuser('$DJANGO_SUPERUSER_USERNAME','$DJANGO_SUPERUSER_EMAIL','$DJANGO_SUPERUSER_PASSWORD')\" | nautobot-server shell"]
        env {
          name = "SECRET_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret_version.secret_key_v.secret
              version = "1"
            }
          }
        }
        env {
          name  = "DJANGO_SUPERUSER_USERNAME"
          value = local.job_superuser_extra_env.DJANGO_SUPERUSER_USERNAME
        }
        env {
          name  = "DJANGO_SUPERUSER_EMAIL"
          value = local.job_superuser_extra_env.DJANGO_SUPERUSER_EMAIL
        }
        env {
          name  = "DJANGO_SUPERUSER_PASSWORD"
          value = local.job_superuser_extra_env.DJANGO_SUPERUSER_PASSWORD
        }

        dynamic "env" {
          for_each = local.base_common_env
          content {
            name  = env.key
            value = env.value
          }
        }
      }
      vpc_access {
        connector = google_vpc_access_connector.run.id
        egress    = "ALL_TRAFFIC"
      }
    }
  }
  depends_on = [
    google_cloud_run_v2_job.collectstatic,
    google_cloud_run_v2_job.migrate
  ]
}