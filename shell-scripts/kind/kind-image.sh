# # #!/bin/bash

# # # Exit on error
# # set -e

# # # Define home directory based on user
# # if [ "$(whoami)" = "ec2-user" ]; then
# #     USER_HOME="/home/ec2-user"
# # elif [ "$(whoami)" = "root" ]; then
# #     USER_HOME="/home/ec2-user"
# #     # Optional: switch to ec2-user for execution
# #     # exec sudo -u ec2-user "$0" "$@"
# # else
# #     USER_HOME="/home/ec2-user"
# # fi

# # # Define variables
# # ECR_REGISTRY="384570460482.dkr.ecr.ap-south-1.amazonaws.com"
# # KIND_IMAGE="${ECR_REGISTRY}/kindest-node:v1.34.3"
# # CLUSTER_NAME="dev"  # Adjust based on your yaml config
# # CLUSTER_CONFIG="/home/ec2-user/automation-platform/shell-scripts/kind/dev-cluster.yaml"

# # echo "Step 1: Logging into AWS ECR..."
# # aws ecr get-login-password --region ap-south-1 \
# #     | docker login \
# #     --username AWS \
# #     --password-stdin "${ECR_REGISTRY}"

# # echo "Step 2: Installing kind..."
# # source ./kind-installation.sh

# # echo "Step 3: Checking if cluster '${CLUSTER_NAME}' already exists..."
# # if kind get clusters | grep -q "${CLUSTER_NAME}"; then
# #     echo "Cluster '${CLUSTER_NAME}' already exists. Deleting it..."
# #     kind delete cluster --name "${CLUSTER_NAME}"
# # fi

# # echo "Step 4: Pulling kind node image..."
# # docker pull "${KIND_IMAGE}"
# # # docker pull "${ECR_REGISTRY}/instana/mongo:v1"
# # # docker pull "${ECR_REGISTRY}/instana/mysql:v1"
# # # docker pull "${ECR_REGISTRY}/instana/rabbitmq:v1"
# # # docker pull "${ECR_REGISTRY}/redis:alpine3.22"
# # # docker pull "${ECR_REGISTRY}/roboshop/catalogue:v1"
# # # docker pull "${ECR_REGISTRY}/roboshop/cart:v1"
# # # docker pull "${ECR_REGISTRY}/roboshop/user:v1"
# # # docker pull "${ECR_REGISTRY}/roboshop/shipping:v1"
# # # docker pull "${ECR_REGISTRY}/roboshop/payment:v1"
# # # docker pull "${ECR_REGISTRY}/roboshop/web:v1"

# # echo "Step 5: Creating kind cluster..."
# # # Option 1: If your dev-cluster.yaml specifies the image
# # kind create cluster --config "${CLUSTER_CONFIG}"

# # # Option 2: If you need to override the image in the config
# # # kind create cluster --config "${CLUSTER_CONFIG}" --name "${CLUSTER_NAME}" --image "${KIND_IMAGE}"

# # echo "Step 6: Verifying cluster creation..."
# # kubectl cluster-info --context "kind-${CLUSTER_NAME}"
# # kubectl get nodes

# # echo "Step 7: Copying Docker config to kind nodes..."

# # sudo -u ec2-user bash <<'EOF'
# # NODES=$(kind get nodes --name dev 2>/dev/null || echo '')
# # if [ "$NODES" = "" ]; then
# #     echo "No 'dev' cluster found or kind not available"
# #     exit 1
# # fi

# # if [ -f /home/ec2-user/.docker/config.json ]; then
# #     for node in $NODES; do
# #         echo "Copying to $node..."
# #         docker exec $node mkdir -p /root/.docker
# #         docker cp /home/ec2-user/.docker/config.json $node:/root/.docker/config.json
# #     done
# # else
# #     echo "/home/ec2-user/.docker/config.json does not exist"
# # fi

# # for node in $NODES; do
# #     echo "Checking $node..."
# #     docker exec $node ls -la /root/.docker/config.json
# # done
# # EOF

# # echo "Kind cluster setup completed successfully!"


# #!/bin/bash
# set -euo pipefail

# ############################################
# # Safety check
# ############################################
# if [ "$(whoami)" != "ec2-user" ]; then
#   echo "❌ Please run this script as ec2-user"
#   exit 1
# fi

# ############################################
# # Variables
# ############################################
# AWS_REGION="ap-south-1"
# ECR_REGISTRY="384570460482.dkr.ecr.${AWS_REGION}.amazonaws.com"
# KIND_IMAGE="${ECR_REGISTRY}/kindest-node:v1.34.3"
# CLUSTER_NAME="dev"
# CLUSTER_CONFIG="/home/ec2-user/automation-platform/shell-scripts/kind/dev-cluster.yaml"
# DOCKER_CONFIG="/home/ec2-user/.docker/config.json"

# ############################################
# # Step 0: Docker access check
# ############################################
# echo "🔍 Checking Docker access..."
# if ! docker ps >/dev/null 2>&1; then
#   echo "❌ Docker is not accessible. Ensure ec2-user is in docker group:"
#   echo "   sudo usermod -aG docker ec2-user && logout/login"
#   exit 1
# fi

# ############################################
# # Step 1: Login to ECR
# ############################################
# echo "🔐 Logging into AWS ECR..."
# aws ecr get-login-password --region "${AWS_REGION}" \
#   | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ############################################
# # Step 2: Install KIND (if needed)
# ############################################
# echo "📦 Installing KIND..."
# source ./kind-installation.sh

# ############################################
# # Step 3: Delete existing cluster (if any)
# ############################################
# echo "🔍 Checking existing cluster..."
# if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
#   echo "⚠️  Cluster '${CLUSTER_NAME}' exists. Deleting..."
#   kind delete cluster --name "${CLUSTER_NAME}"
# fi

# ############################################
# # Step 4: Pull KIND node image from ECR
# ############################################
# echo "⬇️  Pulling KIND node image..."
# docker pull "${KIND_IMAGE}"

# ############################################
# # Step 5: Create KIND cluster
# ############################################
# echo "🚀 Creating KIND cluster..."
# kind create cluster --name "${CLUSTER_NAME}" --config "${CLUSTER_CONFIG}"

# ############################################
# # Step 6: Verify cluster
# ############################################
# echo "✅ Verifying cluster..."
# kubectl cluster-info --context "kind-${CLUSTER_NAME}"
# kubectl get nodes

# ############################################
# # Step 7: Copy Docker credentials into KIND nodes
# ############################################
# echo "🔑 Copying Docker credentials to KIND nodes..."

# if [ ! -f "${DOCKER_CONFIG}" ]; then
#   echo "❌ Docker config not found: ${DOCKER_CONFIG}"
#   exit 1
# fi

# NODES=$(kind get nodes --name "${CLUSTER_NAME}")

# for node in ${NODES}; do
#   echo "   → ${node}"
#   docker exec "${node}" mkdir -p /root/.docker
#   docker cp "${DOCKER_CONFIG}" "${node}:/root/.docker/config.json"
# done

# ############################################
# # Step 8: Verify inside nodes
# ############################################
# echo "🔎 Verifying credentials inside nodes..."

# for node in ${NODES}; do
#   docker exec "${node}" ls -l /root/.docker/config.json
# done

# ############################################
# # Done
# ############################################
# echo "🎉 KIND cluster '${CLUSTER_NAME}' setup completed successfully!"

#!/bin/bash
set -euo pipefail

if [ "$(whoami)" != "ec2-user" ]; then
  echo "❌ Run as ec2-user only"
  exit 1
fi

AWS_REGION="ap-south-1"
ECR_REGISTRY="384570460482.dkr.ecr.${AWS_REGION}.amazonaws.com"
KIND_IMAGE="${ECR_REGISTRY}/kindest-node:v1.34.3"
CLUSTER_NAME="dev"
CLUSTER_CONFIG="/home/ec2-user/automation-platform/shell-scripts/kind/dev-cluster.yaml"
DOCKER_CONFIG="$HOME/.docker/config.json"

echo "🔍 Checking docker access..."
docker ps >/dev/null

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
 | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "📦 Installing tools..."
sudo /home/ec2-user/automation-platform/shell-scripts/kind/kind-installation.sh

echo "🧹 Checking existing cluster..."
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind delete cluster --name "${CLUSTER_NAME}"
fi

echo "⬇️ Pulling node image..."
docker pull "$KIND_IMAGE"

echo "🚀 Creating cluster..."
kind create cluster --name "$CLUSTER_NAME" --config "$CLUSTER_CONFIG"

echo "✅ Verifying..."
kubectl get nodes

echo "🔑 Copying docker credentials into nodes..."

if [ ! -f "$DOCKER_CONFIG" ]; then
  echo "Docker config missing"
  exit 1
fi

NODES=$(kind get nodes --name "$CLUSTER_NAME")

for node in $NODES; do
  docker exec "$node" mkdir -p /root/.docker
  docker cp "$DOCKER_CONFIG" "$node:/root/.docker/config.json"
done

echo "🎉 KIND cluster ready"

