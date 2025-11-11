# =====================================================
# EC2 INSTANCE: JENKINS SERVER
# =====================================================

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.jenkins.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  # IP pública
  associate_public_ip_address = true

  # IAM Instance Profile
  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  # Key pair para SSH
  key_name = aws_key_pair.jenkins.key_name

  # User data: Instalación Jenkins
  user_data = <<-EOF
#!/bin/bash
set -e
exec > >(tee /var/log/jenkins-setup.log)
exec 2>&1
echo "Starting Jenkins setup at $(date)"
yum update -y
amazon-linux-extras install java-openjdk11 -y
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins
amazon-linux-extras install docker -y
yum install -y git
systemctl enable jenkins
systemctl start jenkins
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins
systemctl restart jenkins
echo "Jenkins setup completed at $(date)"
EOF


  tags = {
    Name        = "pcfactory-jenkins"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "CI/CD Jenkins Server"
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true

    tags = {
      Name = "pcfactory-jenkins-root"
    }
  }

  depends_on = [
    aws_internet_gateway.jenkins,
    aws_route_table_association.jenkins,
    aws_iam_instance_profile.jenkins
  ]
}

# =====================================================
# IAM ROLE FOR JENKINS
# =====================================================

resource "aws_iam_role" "jenkins" {
  name = "pcfactory-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "pcfactory-jenkins-role"
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_ec2" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "pcfactory-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# =====================================================
# TLS KEY PAIR - GENERADO AUTOMÁTICAMENTE
# =====================================================

resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins" {
  key_name   = "pcfactory-jenkins-auto"
  public_key = tls_private_key.jenkins.public_key_openssh

  depends_on = [tls_private_key.jenkins]
}

# Guardar private key en archivo
resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins.private_key_pem
  filename        = "${path.module}/jenkins_private_key.pem"
  file_permission = "0600"

  depends_on = [tls_private_key.jenkins]
}