# #!/bin/bash

# echo "======== Donwloading and installing kind, kubectl, helm, kubectx, k9s, kubecolor ======================="
# [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
# chmod +x ./kind
# sudo mv ./kind /usr/local/bin/kind

# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/kubectl

# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
# sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
# sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# curl -sS https://webinstall.dev/k9s | bash

# curl -LO https://github.com/kubecolor/kubecolor/releases/download/v0.5.1/kubecolor_0.5.1_linux_amd64.tar.gz
# tar -xvf kubecolor_0.5.1_linux_amd64.tar.gz
# sudo mv kubecolor /usr/local/bin/

# echo "============ tmux and bash configuration ====================="
# echo "set -g mouse on" >> ~/.tmux.conf

# echo "alias k='kubectl'" >> ~/.bashrc
# echo "alias kubectl='kubecolor'" >> ~/.bashrc

# source ~/.bashrc

# rm -rf kubecolor_0.5.1_linux_amd64.tar.gz LICENSE README.md get_helm.sh


#!/bin/bash
set -e

# Configure tmux for ec2-user
EC2_USER_HOME="/home/ec2-user"
TMUX_CONF="$EC2_USER_HOME/.tmux.conf"

# Ensure ec2-user home exists and has correct permissions
mkdir -p "$EC2_USER_HOME"
chown -R ec2-user:ec2-user "$EC2_USER_HOME"

echo "======== Downloading and installing kind, kubectl, helm, kubectx, k9s, kubecolor ========"

# Create temp directory for downloads
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to download with retry
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -L -f -s "$url" -o "$output"; then
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo "Download failed, retrying ($retry_count/$max_retries)..."
        sleep 2
    done
    echo "Failed to download $url after $max_retries attempts"
    return 1
}

# Install kind
if ! command_exists kind; then
    echo "Installing kind..."
    KIND_VERSION="v0.30.0"
    if [ "$(uname -m)" = "x86_64" ]; then
        download_with_retry "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" ./kind
    elif [ "$(uname -m)" = "aarch64" ]; then
        download_with_retry "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-arm64" ./kind
    else
        echo "Unsupported architecture: $(uname -m)"
        exit 1
    fi
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "kind installed successfully"
else
    echo "kind already installed: $(kind --version)"
fi

# Install kubectl
if ! command_exists kubectl; then
    echo "Installing kubectl..."
    KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    download_with_retry "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" ./kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "kubectl installed successfully"
else
    echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null | head -1)"
fi

# Install Helm
if ! command_exists helm; then
    echo "Installing Helm..."
    download_with_retry "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh
    echo "Helm installed successfully"
else
    echo "Helm already installed: $(helm version --short)"
fi

# Install kubectx and kubens
if ! command_exists kubectx; then
    echo "Installing kubectx and kubens..."
    if [ -d "/opt/kubectx" ]; then
        sudo rm -rf /opt/kubectx
    fi
    sudo git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
    echo "kubectx and kubens installed successfully"
else
    echo "kubectx already installed"
fi

# Install k9s
if ! command_exists k9s; then
    echo "Installing k9s..."
    # Alternative method: direct download (more reliable)
    K9S_VERSION="v0.32.4"
    if [ "$(uname -m)" = "x86_64" ]; then
        download_with_retry "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" k9s.tar.gz
        tar -xzf k9s.tar.gz k9s
        sudo mv k9s /usr/local/bin/
    elif [ "$(uname -m)" = "aarch64" ]; then
        download_with_retry "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_arm64.tar.gz" k9s.tar.gz
        tar -xzf k9s.tar.gz k9s
        sudo mv k9s /usr/local/bin/
    fi
    echo "k9s installed successfully"
else
    echo "k9s already installed"
fi

if [ ! -f /usr/local/bin/kubecolor ]; then
    curl -LO https://github.com/kubecolor/kubecolor/releases/download/v0.5.1/kubecolor_0.5.1_linux_amd64.tar.gz
    tar -xvf kubecolor_0.5.1_linux_amd64.tar.gz
    sudo mv kubecolor /usr/local/bin/
    rm kubecolor_0.5.1_linux_amd64.tar.gz
else
    echo "kubecolor already installed"
fi

echo "============ tmux and bash configuration ====================="
echo "set -g mouse on" >> /home/ec2-user/.tmux.conf
echo "alias k='kubectl'" >> /home/ec2-user/.bashrc
echo "alias kubectl='kubecolor'" >> /home/ec2-user/.bashrc
source /home/ec2-user/.bashrc
