resource "google_compute_network" "main" {
  name                    = "nb-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "run" {
  name          = "nb-run-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
  purpose       = "PRIVATE"
  stack_type    = "IPV4_ONLY"
}

resource "google_vpc_access_connector" "run" {
  name          = "nb-vpc-connector"
  region        = var.region
  network       = google_compute_network.main.name
  ip_cidr_range = "10.9.0.0/28"
  min_instances = 2
  max_instances = 3
}
