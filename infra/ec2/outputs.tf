output "jumpbox_public_ip" {
  description = "Use this in PuTTY as ubuntu@<ip>"
  value       = aws_instance.jumpbox.public_ip
}

output "putty_host" {
  value = "ubuntu@${aws_instance.jumpbox.public_ip}"
}

output "jenkins_url" {
  value = "http://${aws_instance.jumpbox.public_ip}:8080"
}

output "key_file" {
  description = "PuTTY private key, created in this folder"
  value       = "infra/ec2/${null_resource.key_pair.triggers.key_name}.ppk"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.web.repository_url
}

output "vpc_id" {
  value = aws_vpc.lab.id
}
