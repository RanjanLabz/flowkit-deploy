terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_compute_network" "flowkit" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.name_prefix}-subnet"
  network       = google_compute_network.flowkit.id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.name_prefix}-ssh"
  network = google_compute_network.flowkit.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_allowed_cidr]
}

resource "google_compute_firewall" "worker" {
  name    = "${var.name_prefix}-worker"
  network = google_compute_network.flowkit.id
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = [var.api_allowed_cidr]
}

resource "google_compute_firewall" "vnc" {
  count   = var.vnc_allowed_cidr == "" ? 0 : 1
  name    = "${var.name_prefix}-vnc"
  network = google_compute_network.flowkit.id
  allow {
    protocol = "tcp"
    ports    = ["5901-5999", "6080-6579"]
  }
  source_ranges = [var.vnc_allowed_cidr]
}

resource "google_compute_instance" "worker" {
  name         = "${var.name_prefix}-worker"
  machine_type = var.machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {}
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    repo_url             = var.repo_url
    repo_branch          = var.repo_branch
    worker_id            = var.worker_id
    orchestrator_url     = var.orchestrator_url
    orchestrator_api_key = var.orchestrator_api_key
    redis_url            = var.redis_url
    vnc_password         = var.vnc_password
    app_dir              = var.app_dir
  })

  tags = ["flowkit-worker"]
}
