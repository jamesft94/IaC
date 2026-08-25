output "public_ip_address" {
  description = "public ip address of the instance"
  value = aws_nat_gateway.nat.public_ip
}

output "ssh_command" {
  description = "handy command to ssh into the instance"
  value = "ssh ubuntu@${var.vm_name}"
}

output "instance_type" {
  description = "show instance type"
  value = aws_instance.vm.instance_type
}