#!/bin/bash

# Exit on error
set -e

# Define home directory based on user
if [ "$(whoami)" = "ec2-user" ]; then
    USER_HOME="/home/ec2-user"
elif [ "$(whoami)" = "root" ]; then
    USER_HOME="/home/ec2-user"
    # Optional: switch to ec2-user for execution
    # exec sudo -u ec2-user "$0" "$@"
else
    USER_HOME="/home/ec2-user"
fi

# Define variables
ECR_REGISTRY="384570460482.dkr.ecr.ap-south-1.amazonaws.com"
KIND_IMAGE="${ECR_REGISTRY}/kindest-node:v1.34.3"
CLUSTER_NAME="dev"  # Adjust based on your yaml config
CLUSTER_CONFIG="/home/ec2-user/automation-platform/shell-scripts/kind/dev-cluster.yaml"

echo "Step 1: Logging into AWS ECR..."
aws ecr get-login-password --region ap-south-1 \
    | docker login \
    --username AWS \
    --password-stdin "${ECR_REGISTRY}"

echo "Step 2: Installing kind..."
source ./kind-installation.sh

echo "Step 3: Checking if cluster '${CLUSTER_NAME}' already exists..."
if kind get clusters | grep -q "${CLUSTER_NAME}"; then
    echo "Cluster '${CLUSTER_NAME}' already exists. Deleting it..."
    kind delete cluster --name "${CLUSTER_NAME}"
fi

echo "Step 4: Pulling kind node image..."
docker pull "${KIND_IMAGE}"
# docker pull "${ECR_REGISTRY}/instana/mongo:v1"
# docker pull "${ECR_REGISTRY}/instana/mysql:v1"
# docker pull "${ECR_REGISTRY}/instana/rabbitmq:v1"
# docker pull "${ECR_REGISTRY}/redis:alpine3.22"
# docker pull "${ECR_REGISTRY}/roboshop/catalogue:v1"
# docker pull "${ECR_REGISTRY}/roboshop/cart:v1"
# docker pull "${ECR_REGISTRY}/roboshop/user:v1"
# docker pull "${ECR_REGISTRY}/roboshop/shipping:v1"
# docker pull "${ECR_REGISTRY}/roboshop/payment:v1"
# docker pull "${ECR_REGISTRY}/roboshop/web:v1"

echo "Step 5: Creating kind cluster..."
# Option 1: If your dev-cluster.yaml specifies the image
kind create cluster --config "${CLUSTER_CONFIG}"

# Option 2: If you need to override the image in the config
# kind create cluster --config "${CLUSTER_CONFIG}" --name "${CLUSTER_NAME}" --image "${KIND_IMAGE}"

echo "Step 6: Verifying cluster creation..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl get nodes

echo "Step 7: Copying Docker config to kind nodes..."

sudo -u ec2-user bash <<'EOF'
NODES=$(kind get nodes --name dev 2>/dev/null || echo '')
if [ "$NODES" = "" ]; then
    echo "No 'dev' cluster found or kind not available"
    exit 1
fi

if [ -f /home/ec2-user/.docker/config.json ]; then
    for node in $NODES; do
        echo "Copying to $node..."
        docker exec $node mkdir -p /root/.docker
        docker cp /home/root/.docker/config.json $node:/root/.docker/config.json
    done
else
    echo "/home/ec2-user/.docker/config.json does not exist"
fi

for node in $NODES; do
    echo "Checking $node..."
    docker exec $node ls -la /root/.docker/config.json
done
EOF

echo "Kind cluster setup completed successfully!"
