output "Public_ip_address" {
  description = "public ip address of the instance"
  value = aws_instance.vm.public_ip
}

output "ssh command" {
  description = "handy command to ssh into the instance"
  value = "ssh ${var.admin_username}@${aws_instance.vm.public_ip}"
}

output "region" {
  description = "display which region the instance belongs to"
  value = aws_instance.vm.region
}

output "instance type" {
  description = "show instance type"
  value = aws_instance.vm.instance_type
}