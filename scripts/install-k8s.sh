#!/bin/bash
set -euxo pipefail

echo "[1] Disable swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/' /etc/fstab

echo "[2] Install prerequisites"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

echo "[3] Install containerd (recommended runtime)"
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[3.1] Checking DNS resolution"
if ! ping -c 1 google.com &> /dev/null; then
  echo "⚠️ DNS not working. Setting fallback resolver to 8.8.8.8"
  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
fi

echo "[4] Add Kubernetes GPG key and repository"
sudo mkdir -p /etc/apt/keyrings
if ! timeout 30s curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg; then
  echo "❌ Failed to download Kubernetes GPG key. Check internet/DNS settings."
  exit 1
fi

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[5] Update package index"
sudo apt-get update

echo "[6] Install Kubernetes tools"
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[7] Enable required kernel modules"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

echo "[8] Apply sysctl params"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo "[9] Verify installation"
command -v kubeadm
kubeadm version
kubectl version --client
kubelet --version

echo "[✅] Kubernetes installation complete!"
