resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_password" "db" {
  length  = 24
  special = true
}
resource "google_sql_database_instance" "pg" {
  name                = "nb-pg"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true
  settings {
    tier              = "db-custom-2-7680"
    availability_type = "REGIONAL"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.self_link
      enable_private_path_for_google_cloud_services = true
    }
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    maintenance_window {
      day          = 7
      hour         = 2
      update_track = "stable"
    }
    database_flags {
      name  = "max_connections"
      value = "500"
    }
  }
  depends_on = [
    google_project_service.services,
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "nb" {
  name       = "nautobot"
  instance   = google_sql_database_instance.pg.name
  depends_on = [google_sql_database_instance.pg]
}

resource "google_sql_user" "app" {
  name       = "nautobot"
  instance   = google_sql_database_instance.pg.name
  password   = random_password.db.result
  depends_on = [google_sql_database_instance.pg]
}
