#!/bin/bash
set -e

##############################################
# CloudWatch Logs Setup (capture userdata)
##############################################

yum update -y
yum install -y amazon-cloudwatch-agent

# Redirect all future userdata logs to file + syslog
exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ec2/userdata",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

systemctl enable --now amazon-cloudwatch-agent

echo "CloudWatch agent configured."

##############################################
# Install Required Packages
##############################################

dnf install -y git docker tmux tree

# Start docker service
systemctl enable --now docker

# Add ec2-user to docker group
usermod -aG docker ec2-user


##############################################
# Install Docker Compose
##############################################

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


##############################################
# Install Docker Buildx Plugin
##############################################

mkdir -p /usr/libexec/docker/cli-plugins/

curl -sSL \
  https://github.com/docker/buildx/releases/download/v0.17.1/buildx-v0.17.1.linux-amd64 \
  -o /usr/libexec/docker/cli-plugins/docker-buildx

chmod +x /usr/libexec/docker/cli-plugins/docker-buildx


##############################################
# Install Trivy
##############################################

curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh


##############################################
# Clone Repository
##############################################

rm -rf /home/ec2-user/scripts
git clone https://github.com/konka-devops-lab/scripts.git /home/ec2-user/scripts
chown -R ec2-user:ec2-user /home/ec2-user/scripts

git clone https://github.com/konka-devops-lab/crud-app.git /home/ec2-user/crud-app
chown -R ec2-user:ec2-user /home/ec2-user/crud-app

##############################################
# Version Checks (for debugging and validation)
##############################################

echo "===== VERSION CHECKS ====="
docker --version
docker-compose --version
docker buildx version
trivy --version
echo "=========================="



echo "USERDATA COMPLETED SUCCESSFULLY"
##############################################
