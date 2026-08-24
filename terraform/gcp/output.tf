output "project" {
  value = var.gcp_project_id
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${var.vm_name}"
}
