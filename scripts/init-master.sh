#!/bin/bash
set -xe

echo "Initializing Kubernetes master node..."
sudo kubeadm init \
  --pod-network-cidr=10.10.60.0/16 \
  --ignore-preflight-errors=Swap \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# Configure kubectl for root
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Make admin.conf readable for scp
sudo cp /etc/kubernetes/admin.conf /tmp/admin.conf
sudo chmod 644 /tmp/admin.conf

# Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Remove taints (optional)
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Generate join command with 24h token
kubeadm token create --ttl 24h --print-join-command > /tmp/join.sh
chmod 755 /tmp/join.sh

echo "Master node initialized successfully!"