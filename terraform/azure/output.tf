output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# output "public_ip_address" {
#   value = azurerm_public_ip.pip.ip_address
# }

output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "tailscale_hostname" {
  description = "Tailscale hostname assigned to the VM"
  value       = var.vm_name
}

output "vm_user" {
  description = "SSH username for the VM"
  value       = var.admin_username
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${var.vm_name}"
}
