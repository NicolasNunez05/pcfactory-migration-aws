#!/bin/bash
set -e

# Update
apt-get update
apt-get install -y openjdk-17-jdk wget curl git docker.io

# Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins

# Docker
usermod -aG docker jenkins
systemctl start docker
systemctl enable docker

# Jenkins
systemctl start jenkins
systemctl enable jenkins

echo "Jenkins iniciado en puerto 8080"
