resource "null_resource" "run_migration" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud run jobs execute ${resource.google_cloud_run_v2_job.migrate.name} --region ${var.region} --wait"
  }
  depends_on = [google_cloud_run_v2_job.migrate]
}

resource "null_resource" "run_collectstatic" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud run jobs execute ${resource.google_cloud_run_v2_job.collectstatic.name} --region ${var.region} --wait"
  }
  depends_on = [google_cloud_run_v2_job.collectstatic]
}

resource "null_resource" "run_createsuperuser" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud run jobs execute ${resource.google_cloud_run_v2_job.createsuperuser.name} --region ${var.region} --wait"
  }
  depends_on = [google_cloud_run_v2_job.createsuperuser]
}

resource "google_cloud_run_v2_service" "web" {
  name                = "cloud-run-web"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  template {
    service_account = google_service_account.web.email
    containers {
      image   = local.image
      command = ["/app/entrypoint.sh"]
      ports { container_port = 8080 }
      resources {
        cpu_idle = true
        limits   = { cpu = "2", memory = "2Gi" }
      }
      env {
        name  = "NAUTOBOT_UWSGI_HTTP"
        value = local.NAUTOBOT_UWSGI_HTTP
      }
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
        for_each = merge(
          local.base_common_env,
          local.service_extra_env
        )
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
    scaling {
      min_instance_count = 1
      max_instance_count = var.run_max_instances_web
    }
    max_instance_request_concurrency = 60
    timeout                          = "60s"
  }
  depends_on = [
    google_project_service.services,
    resource.null_resource.run_migration,
    resource.null_resource.run_collectstatic,
    resource.null_resource.run_createsuperuser
  ]
}

resource "google_cloud_run_v2_service_iam_member" "noauth" {
  project  = google_cloud_run_v2_service.web.project
  location = google_cloud_run_v2_service.web.location
  name     = google_cloud_run_v2_service.web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service" "worker" {
  name                = "cloud-run-worker"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false
  template {
    service_account = google_service_account.worker.email
    containers {
      image   = local.image
      command = ["/app/entrypoint-worker.sh"]
      resources { limits = { cpu = "1", memory = "1Gi" } }

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
        for_each = merge(
          local.base_common_env,
          local.service_extra_env
        )
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
    scaling {
      min_instance_count = 1
      max_instance_count = var.run_max_instances_worker
    }
    max_instance_request_concurrency = 1
    timeout                          = "1800s"

    annotations = {
      "run.googleapis.com/cpu-throttling" = "false"
      "run.googleapis.com/cpu-boost"      = "true"
    }
  }
  depends_on = [
    google_project_service.services,
    resource.null_resource.run_migration,
    resource.null_resource.run_collectstatic,
    resource.null_resource.run_createsuperuser
  ]
}

resource "google_cloud_run_v2_service" "beat" {
  name                = "cloud-run-beat"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false
  template {
    service_account = google_service_account.beat.email
    containers {
      image   = local.image
      command = ["/app/entrypoint-beat.sh"]
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
        for_each = merge(
          local.base_common_env,
          local.service_extra_env
        )
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
    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }
    max_instance_request_concurrency = 1
    timeout                          = "900s"
    annotations = {
      "run.googleapis.com/cpu-throttling" = "false"
      "run.googleapis.com/cpu-boost"      = "true"
    }
  }
  depends_on = [
    google_project_service.services,
    resource.null_resource.run_migration,
    resource.null_resource.run_collectstatic,
    resource.null_resource.run_createsuperuser
  ]
}