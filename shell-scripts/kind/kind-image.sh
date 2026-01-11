#!/bin/bash

# Exit on error
set -e

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

echo "Step 5: Creating kind cluster..."
# Option 1: If your dev-cluster.yaml specifies the image
kind create cluster --config "${CLUSTER_CONFIG}"

# Option 2: If you need to override the image in the config
# kind create cluster --config "${CLUSTER_CONFIG}" --name "${CLUSTER_NAME}" --image "${KIND_IMAGE}"

echo "Step 6: Verifying cluster creation..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl get nodes

echo "Kind cluster setup completed successfully!"


