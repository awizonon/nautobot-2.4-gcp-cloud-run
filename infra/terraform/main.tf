# APIs enabling (optionally use google_project_service resources)
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "dns.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "cloudscheduler.googleapis.com",
    "certificatemanager.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
