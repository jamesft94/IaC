variable "region" {
  description = "GCP region for the resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP ZONE"
  type        = string
  default     = "us-central1-c"
}

variable "gcp_project_id" {
  description = "project id on gcp"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-demo"
}

variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vm_name" {
  description = "Name of the Linux VM"
  type        = string
  default     = "demo-compute"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "n4-standard-2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "test-user"
}

variable "image-os" {
  description = "OS image to be installed on the vm"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "OS-disk-type" {
  description = "type of disk used for the OS Image"
  type        = string
  default     = "hyperdisk-balanced"
}

variable "tailnet-key" {
  description = "access key to the tailnet network reusable and ephemeral"
  type        = string
}
