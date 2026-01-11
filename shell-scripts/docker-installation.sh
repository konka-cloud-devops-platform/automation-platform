# set -e

# ##############################################
# # CloudWatch Logs Setup (capture userdata)
# ##############################################

# yum update -y
# yum install -y amazon-cloudwatch-agent

# # Redirect all future userdata logs to file + syslog
# exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

# mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

# cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
# {
#   "logs": {
#     "logs_collected": {
#       "files": {
#         "collect_list": [
#           {
#             "file_path": "/var/log/user-data.log",
#             "log_group_name": "/ec2/userdata",
#             "log_stream_name": "{instance_id}"
#           }
#         ]
#       }
#     }
#   }
# }
# EOF

# systemctl enable --now amazon-cloudwatch-agent

# echo "CloudWatch agent configured."

# ##############################################
# # Install Required Packages
# ##############################################

# dnf install -y git docker tmux tree

# # Start docker service
# systemctl enable --now docker

# # Add ec2-user to docker group
# usermod -aG docker ec2-user


# ##############################################
# # Install Docker Compose
# ##############################################

# curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
#   -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose


# ##############################################
# # Install Docker Buildx Plugin
# ##############################################

# mkdir -p /usr/libexec/docker/cli-plugins/

# curl -sSL \
#   https://github.com/docker/buildx/releases/download/v0.17.1/buildx-v0.17.1.linux-amd64 \
#   -o /usr/libexec/docker/cli-plugins/docker-buildx

# chmod +x /usr/libexec/docker/cli-plugins/docker-buildx


# ##############################################
# # Install Trivy
# ##############################################

# curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh


# ##############################################
# # Clone Repository
# ##############################################

# rm -rf /home/ec2-user/scripts
# git clone https://github.com/konka-cloud-devops-platform/automation-platform.git /home/ec2-user/automation-platform
# chown -R ec2-user:ec2-user /home/ec2-user/automation-platform

# cd /home/ec2-user/automation-platform/shell-scripts/kind
# source ./kind-image.sh

# git clone https://github.com/konka-cloud-devops-platform/kubernetes-platform.git /home/ec2-user/kubernetes-platform
# chown -R ec2-user:ec2-user /home/ec2-user/kubernetes-platform

# ##############################################
# # Version Checks (for debugging and validation)
# ##############################################

# echo "===== VERSION CHECKS ====="
# docker --version
# docker-compose --version
# docker buildx version
# trivy --version
# echo "=========================="



# echo "USERDATA COMPLETED SUCCESSFULLY"
# ##############################################

#!/bin/bash
set -e

##############################################
# CloudWatch Logs Setup (capture userdata)
##############################################

yum update -y -q
yum install -y amazon-cloudwatch-agent jq

# Create log directory and redirect all future output
mkdir -p /var/log/
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

echo "Starting userdata execution..."

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ec2/userdata",
            "log_stream_name": "${INSTANCE_ID}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "CloudWatch agent configured."

##############################################
# Install Required Packages
##############################################

echo "Installing required packages..."
dnf install -y git docker tmux tree

# Configure Docker
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Start docker service
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

##############################################
# Install Docker Compose
##############################################

echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create symlink for docker-compose v2 compatibility
ln -sf /usr/local/bin/docker-compose /usr/libexec/docker/cli-plugins/docker-compose

##############################################
# Install Docker Buildx Plugin
##############################################

echo "Installing Docker Buildx..."
mkdir -p /usr/libexec/docker/cli-plugins/
BUILDX_VERSION="v0.17.1"

curl -sSL \
  "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" \
  -o /usr/libexec/docker/cli-plugins/docker-buildx

chmod +x /usr/libexec/docker/cli-plugins/docker-buildx

# Create buildx builder with correct context
docker buildx create --name builder --use

##############################################
# Install Trivy
##############################################

echo "Installing Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
trivy --download-db-only

##############################################
# Clone Repository
##############################################

echo "Cloning repositories..."
rm -rf /home/ec2-user/automation-platform

# Clone automation platform
git clone https://github.com/konka-cloud-devops-platform/automation-platform.git /home/ec2-user/automation-platform
chown -R ec2-user:ec2-user /home/ec2-user/automation-platform

# Execute kind-image.sh if it exists
if [ -f "/home/ec2-user/automation-platform/shell-scripts/kind/kind-image.sh" ]; then
    echo "Running kind-image.sh..."
    cd /home/ec2-user/automation-platform/shell-scripts/kind
    # Source as ec2-user to preserve environment
    sudo -u ec2-user bash -c "source ./kind-image.sh" || echo "Warning: kind-image.sh execution had issues"
fi

# Clone kubernetes platform
git clone https://github.com/konka-cloud-devops-platform/kubernetes-platform.git /home/ec2-user/kubernetes-platform
chown -R ec2-user:ec2-user /home/ec2-user/kubernetes-platform



##############################################
# Version Checks (for debugging and validation)
##############################################

echo "===== VERSION CHECKS ====="
{
    docker --version
    docker-compose --version
    docker buildx version
    trivy --version
    kubectl version --client --short 2>/dev/null || echo "kubectl not properly installed"
} >> /var/log/user-data.log 2>&1
echo "=========================="

##############################################
# Final Setup and Permissions
##############################################

# Set up bash profile for ec2-user
cat <<EOF >> /home/ec2-user/.bashrc
export PATH=\$PATH:/usr/local/bin
alias k='kubectl'
complete -o default -F __start_kubectl k
EOF

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user/

# Ensure docker socket permissions
chmod 666 /var/run/docker.sock 2>/dev/null || true

# Restart docker to apply all changes
systemctl restart docker

# Wait for docker to be ready
sleep 5

echo "USERDATA COMPLETED SUCCESSFULLY at $(date)"