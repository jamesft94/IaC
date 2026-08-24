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

variable "address_space" {
  description = "CIDR block for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
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
  default     = "n4d-standard-2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "pubkey" {
  description = "path to the ssh public key to be used"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "image-os" {
  description = "OS image to be installed on the vm"
  type = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2604-resolute-amd64-v2026072"
}

variable "OS-disk-type" {
  description = "type of disk used for the OS Image"
  type = string
  default = "pd-standard"
}