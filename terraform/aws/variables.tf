variable "region" {
  description = "aws region for the resources"
  type        = string
  default     = "eu-north-1"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-demo-terraform"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-demo"
}

variable "address_space" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_name" {
  description = "Name of the Linux VM"
  type        = string
  default     = "test-compute"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "t3.small"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "mehrdad"
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

variable "tailnet-key" {
  description = "access key to the tailnet network reusable and ephemeral"
  type        = string
}