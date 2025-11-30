resource "google_service_account" "web" {
  account_id = "nb-web-sa"
}
resource "google_service_account" "worker" {
  account_id = "nb-worker-sa"
}
resource "google_service_account" "beat" {
  account_id = "nb-beat-sa"
}

# Grant minimal roles (add per your policy)
resource "google_project_iam_member" "web_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.web.email}"
}
resource "google_project_iam_member" "worker_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.worker.email}"
}
resource "google_project_iam_member" "beat_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.beat.email}"
}

####Bucket SA

resource "google_project_iam_member" "web_sa_bucket" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.web.email}"
}
resource "google_project_iam_member" "worker_sa_bucket" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.worker.email}"
}
resource "google_project_iam_member" "beat_sa_bucket" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.beat.email}"
}

resource "google_project_iam_member" "web_sql_1" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.web.email}"
}
resource "google_project_iam_member" "worker_sql_1" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.worker.email}"
}
resource "google_project_iam_member" "beat_sql_1" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.beat.email}"
}