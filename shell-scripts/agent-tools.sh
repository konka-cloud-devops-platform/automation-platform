#!/bin/bash

LOG_FILE="/tmp/setup_$(date +%Y-%m-%d_%H-%M).log"

LOG() {
  echo -e "$1" &>>"$LOG_FILE"
  if [ "$2" -eq 0 ]; then
    echo -e "\e[32m[SUCCESS]\e[0m $1"
  else
    echo -e "\e[31m[FAILED]\e[0m $1"
  fi
}

# Check for sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" &>>"$LOG_FILE"
   exit 1
fi

# Update system
dnf update -y &>>"$LOG_FILE"
LOG "System update completed" $?

# Install Node.js 20.x
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - &>>"$LOG_FILE"
LOG "NodeSource setup script executed" $?
dnf update -y &>>"$LOG_FILE"
dnf install -y nodejs &>>"$LOG_FILE"
LOG "Node.js installation completed" $?

# Install Terraform
yum install -y yum-utils &>>"$LOG_FILE"
LOG "yum-utils installed" $?
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo &>>"$LOG_FILE"
LOG "HashiCorp repository added" $?
yum -y install terraform &>>"$LOG_FILE"
LOG "Terraform installation completed" $?

# Install Java 11 (Amazon Corretto)
yum install -y java-11-amazon-corretto-devel &>>"$LOG_FILE"
LOG "Java 11 Amazon Corretto installed" $?

# Install Git
dnf install -y git &>>"$LOG_FILE"
LOG "Git installation completed" $?

# Install Docker
dnf install -y docker &>>"$LOG_FILE"
LOG "Docker installation completed" $?
systemctl start docker &>>"$LOG_FILE"
LOG "Docker service started" $?
usermod -aG docker ec2-user &>>"$LOG_FILE"
LOG "User 'ec2-user' added to Docker group" $?
systemctl restart docker &>>"$LOG_FILE"
LOG "Docker service restarted" $?

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>>"$LOG_FILE"
LOG "Docker Compose downloaded" $?
chmod +x /usr/local/bin/docker-compose &>>"$LOG_FILE"
LOG "Docker Compose installed" $?

if [ -d "/opt/maven" ]; then
  sudo rm -rf /opt/maven &>>"$LOG_FILE"
  LOG "Old Maven directory removed" $?
fi

# Recreate Maven directory
sudo mkdir -p /opt/maven &>>"$LOG_FILE"
LOG "Maven directory created" $?

# Download and extract Maven 3.6.3
cd /opt || exit
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz &>>"$LOG_FILE"
LOG "Maven 3.6.3 downloaded" $?
sudo tar -xvzf apache-maven-3.6.3-bin.tar.gz -C /opt/maven --strip-components=1 &>>"$LOG_FILE"
LOG "Maven 3.6.3 extracted" $?

# Add Maven to PATH
if ! grep -q 'export PATH=/opt/maven/bin:$PATH' /home/ec2-user/.bash_profile; then
  echo 'export PATH=/opt/maven/bin:$PATH' >> /home/ec2-user/.bash_profile
  source /home/ec2-user/.bash_profile
  LOG "Maven added to PATH" $?
else
  LOG "Maven already in PATH, skipping" 0
fi

# Check if Maven is in PATH
echo $PATH &>>"$LOG_FILE"
which mvn &>>"$LOG_FILE"

# Test Maven
mvn -version &>>"$LOG_FILE"
LOG "Maven installation verified" $?
