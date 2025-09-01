provider "null" {}

##############################
# STEP 1: Master Installation
##############################
resource "null_resource" "install_master_k8s" {
  triggers = {
    script_hash = filesha256("${path.module}/scripts/install-k8s.sh")
  }

  connection {
    host        = var.master_ip
    user        = var.ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install-k8s.sh"
    destination = "/tmp/install-k8s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh 2>&1 | tee /tmp/k8s-install.log",
      "grep -q 'Kubernetes installation complete' /tmp/k8s-install.log || { echo 'Installation failed'; exit 1; }"
    ]
  }
}

##############################
# STEP 2: Master Initialization
##############################
resource "null_resource" "init_master" {
  depends_on = [null_resource.install_master_k8s]

  triggers = {
    script_hash = filesha256("${path.module}/scripts/init-master.sh")
  }

  connection {
    host        = var.master_ip
    user        = var.ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/init-master.sh"
    destination = "/tmp/init-master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-master.sh",
      "/tmp/init-master.sh 2>&1 | tee /tmp/k8s-init.log",
      "grep -q 'Master node ready' /tmp/k8s-init.log || { echo 'Initialization failed'; exit 1; }",
      # Create long-lived join token (24 hours)
      "kubeadm token create --ttl 24h --print-join-command > /tmp/join.sh",
      "cp /etc/kubernetes/admin.conf /tmp/kubeconfig",
      "chmod 644 /tmp/join.sh /tmp/kubeconfig"
    ]
  }
}

##############################
# STEP 3: Worker Installation
##############################
resource "null_resource" "install_worker" {
  count = length(var.worker_ips)

  depends_on = [null_resource.init_master]

  triggers = {
    install_script = filesha256("${path.module}/scripts/install-k8s.sh")
    join_script    = filesha256("${path.module}/scripts/join-worker.sh")
  }

  connection {
    host        = var.worker_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install-k8s.sh"
    destination = "/tmp/install-k8s.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/join-worker.sh"
    destination = "/tmp/join-worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      # Install Kubernetes
      "chmod +x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh 2>&1 | tee /tmp/k8s-install.log",
      "grep -q 'Kubernetes installation complete' /tmp/k8s-install.log || { echo 'Worker installation failed'; exit 1; }",
      
      # Join cluster
      "chmod +x /tmp/join-worker.sh",
      "MASTER_IP='${var.master_ip}' SSH_USER='${var.ssh_user}' /tmp/join-worker.sh 2>&1 | tee /tmp/k8s-join.log",
      "grep -q 'Worker node joined successfully' /tmp/k8s-join.log || { echo 'Join failed'; exit 1; }",
      
      # Final verification
      "mkdir -p /root/.kube",
      "cp /tmp/kubeconfig /root/.kube/config",
      "export KUBECONFIG=/root/.kube/config",
      "kubectl get nodes | grep $(hostname)"
    ]
  }
}