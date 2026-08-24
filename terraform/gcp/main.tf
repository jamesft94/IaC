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
  ip_cidr_range = var.subnet_prefix[0]
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_router" "router" {
  name    = "router-${var.vm_name}"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "router-nat" {
  name                               = "nat-${var.vm_name}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
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
  }

  metadata = {
    user-data = templatefile("${path.root}/../../common/cloud-init.yaml", {
      tailnet-key = var.tailnet-key
      hostname    = var.vm_name
    })
  }
}