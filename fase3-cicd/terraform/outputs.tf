# =====================================================
# OUTPUTS
# =====================================================

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Jenkins server public DNS"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${aws_instance.jenkins.public_ip}:${var.jenkins_port}"
}

output "jenkins_initial_password_command" {
  description = "Command to retrieve Jenkins initial admin password"
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.jenkins.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "jenkins_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins.id
}
