variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "eastus"
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
  default     = "vm-demo"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  default     = "P@ssw0rd1234!"
  sensitive   = true
}
