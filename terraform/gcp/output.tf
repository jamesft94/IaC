output "project" {
  value = var.gcp_project_id
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${var.vm_name}"
}

output "Compute_engine_name" {
  value = google_compute_instance.vm.name
}

output "tailscale_hostname" {
  description = "Tailscale hostname assigned to the VM"
  value       = var.vm_name
}

output "vm_user" {
  description = "SSH username for the VM"
  value       = var.admin_username
}
