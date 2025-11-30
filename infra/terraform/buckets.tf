resource "google_storage_bucket" "media" {
  name                        = "${var.project_id}-nautobot-media"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  cors {
    origin = ["*"]
    method = ["GET", "HEAD", "OPTIONS"]
    response_header = [
      "Content-Type",
      "Content-Length",
      "ETag",
      "Last-Modified",
      "Cache-Control",
      "Accept-Ranges",
      "Vary"
    ]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket" "static" {
  name                        = "${var.project_id}-nautobot-static"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  cors {
    origin = ["*"]
    method = ["GET", "HEAD", "OPTIONS"]
    response_header = [
      "Content-Type",
      "Content-Length",
      "ETag",
      "Last-Modified",
      "Cache-Control",
      "Accept-Ranges",
      "Vary"
    ]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket" "backups" {
  name                        = "${var.project_id}-nautobot-sql-backups"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 365 }
  }
}

resource "google_storage_bucket_iam_member" "static_public_view" {
  count  = var.make_bucket_public ? 1 : 0
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_iam_member" "media_public_view" {
  count  = var.make_bucket_public ? 1 : 0
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
