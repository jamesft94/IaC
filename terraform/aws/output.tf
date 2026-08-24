output "Public_ip_address" {
  description = "public ip address of the instance"
  value = aws_instance.vm.public_ip
}

