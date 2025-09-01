Kubernetes Deployment On-Premises with Terraform
📌 Overview
This project provisions an on-premises Kubernetes cluster using Terraform with:

1 Master (10.10.60.22)
2 Workers (10.10.60.173, 10.10.60.147)
PostgreSQL DB, Java Backend API, React.js Frontend

⚙️ Prerequisites
Terraform, kubectl, Docker installed
SSH access to all nodes
Required ports open (6443, 10250, 30000–32767)

🚀 Deployment
terraform init
terraform plan
terraform apply -auto-approve

📦 App Deployment
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml

🔍 Verification
kubectl get nodes
kubectl get pods -A

Access frontend via NodePort/Ingress → calls Java API → connects to PostgreSQL.
