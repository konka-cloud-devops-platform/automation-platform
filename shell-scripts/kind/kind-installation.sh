#!/bin/bash

echo "======== Donwloading and installing kind, kubectl, helm, kubectx, k9s, kubecolor ======================="
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

curl -sS https://webinstall.dev/k9s | bash

curl -LO https://github.com/kubecolor/kubecolor/releases/download/v0.5.1/kubecolor_0.5.1_linux_amd64.tar.gz
tar -xvf kubecolor_0.5.1_linux_amd64.tar.gz
sudo mv kubecolor /usr/local/bin/

echo "============ tmux and bash configuration ====================="
echo "set -g mouse on" >> ~/.tmux.conf

echo "alias k='kubectl'" >> ~/.bashrc
echo "alias kubectl='kubecolor'" >> ~/.bashrc

source ~/.bashrc

rm -rf kubecolor_0.5.1_linux_amd64.tar.gz LICENSE README.md get_helm.sh