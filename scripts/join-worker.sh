#!/bin/bash
set -xe

echo "Fetching cluster credentials from ${MASTER_IP}"
scp -o StrictHostKeyChecking=no ${SSH_USER}@${MASTER_IP}:/tmp/join.sh /tmp/join.sh
scp -o StrictHostKeyChecking=no ${SSH_USER}@${MASTER_IP}:/tmp/kubeconfig /tmp/kubeconfig

echo "Joining Kubernetes cluster"
bash /tmp/join.sh

echo "Verifying node status"
mkdir -p $HOME/.kube
cp /tmp/kubeconfig $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes -o wide | grep $(hostname)

echo "Worker node joined successfully"