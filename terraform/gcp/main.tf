terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
  zone    = var.zone
}

# --- Network Infrastructure ---

resource "google_compute_network" "vpc" {
  name                    = var.vnet_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-main"
  ip_cidr_range = var.subnet_prefix[0] # e.g. "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# --- Firewall Rule (NSG Equivalent) ---

# resource "google_compute_firewall" "allow_ssh" {
#   name    = "allow-ssh"
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = var.allowed_ips
#   target_tags   = ["ssh-allowed"]
# }

# --- Compute Engine (VM Instance) ---

resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.vm_size # e.g. "e2-small" or "e2-medium"
  zone         = var.zone

  tags   = ["ssh-allowed"]
  labels = local.tags

  boot_disk {
    initialize_params {
      image = var.image-os
      size  = 30
      type  = var.OS-disk-type
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    # An empty access_config allocates an ephemeral public IP
    access_config {}
  }

  # Injects SSH public key directly into instance metadata
  metadata = {
    ssh-keys               = "${var.admin_username}:${trimspace(file(pathexpand(var.pubkey)))}"
    block-project-ssh-keys = "true"
  }
}