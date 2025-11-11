output "jenkins_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "Jenkins public IP"
}

output "jenkins_url" {
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
  description = "Jenkins URL"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.pcfactory.repository_url
  description = "ECR repository URL"
}
