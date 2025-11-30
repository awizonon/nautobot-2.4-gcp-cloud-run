resource "random_password" "secret_key" {
  length  = 64
  special = true
}
resource "google_secret_manager_secret" "secret_key" {
  secret_id = "nautobot-secret-key"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "secret_key_v" {
  secret      = google_secret_manager_secret.secret_key.id
  secret_data = random_password.secret_key.result
}
