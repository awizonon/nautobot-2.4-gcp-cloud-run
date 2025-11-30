resource "google_redis_instance" "redis" {
  name                    = "nb-redis"
  tier                    = "STANDARD_HA"
  memory_size_gb          = 3
  region                  = var.region
  transit_encryption_mode = "DISABLED"
  authorized_network      = google_compute_network.main.id
  depends_on              = [google_project_service.services]
}
