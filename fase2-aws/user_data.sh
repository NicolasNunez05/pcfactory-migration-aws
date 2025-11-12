# archivo: fase2-aws/user_data.sh

#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io
usermod -aG docker ec2-user
systemctl start docker
systemctl enable docker

# Install AWS CLI
apt-get install -y awscli

# Install Git
apt-get install -y git

# Pull and run Jenkins (Docker)
docker run -d \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# Configure AWS credentials (opcional - más seguro usar IAM role)
# aws configure set aws_access_key_id YOUR_KEY
# aws configure set aws_secret_access_key YOUR_SECRET
# aws configure set region us-east-1

echo "✅ Jenkins y Docker instalados automáticamente"
