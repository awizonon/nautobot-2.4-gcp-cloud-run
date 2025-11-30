resource "google_artifact_registry_repository" "repo" {
  format        = "DOCKER"
  location      = var.region
  repository_id = "nautobot"
  depends_on = [google_project_service.services]
}
