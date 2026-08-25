output "public_ip_address" {
  description = "public ip address of the instance"
  value       = aws_nat_gateway.nat.public_ip
}

output "tailscale_hostname" {
  description = "Tailscale hostname assigned to the instance"
  value       = var.vm_name
}

output "vm_user" {
  description = "Default SSH username created by the Canonical Ubuntu image"
  value       = local.vm_user
}

output "ssh_command" {
  description = "handy command to ssh into the instance"
  value       = "ssh ${local.vm_user}@${var.vm_name}"
}

output "instance_type" {
  description = "show instance type"
  value       = aws_instance.vm.instance_type
}
