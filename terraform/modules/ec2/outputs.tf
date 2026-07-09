output "instance_id" {
  value = aws_instance.app.id
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_private_ip" {
  value = aws_instance.app.private_ip
}
