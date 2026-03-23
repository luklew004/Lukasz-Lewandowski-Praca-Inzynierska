output "public_ips" {
  value = aws_instance.servers[*].public_ip
}

output "server_private_ips" {
  value = aws_instance.servers[*].private_ip
}

output "pcs_private_ips" {
  value = aws_instance.pcs[*].private_ip
}

output "extra_interface_ips" {
  value = aws_network_interface.extra_eni[*].private_ips
}
