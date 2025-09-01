variable "master_ip" {
  description = "IP address of the Kubernetes master node"
  type        = string
  default     = "10.10.60.22"
}

variable "worker_ips" {
  description = "List of IP addresses for Kubernetes worker nodes"
  type        = list(string)
  default     = ["10.10.60.173", "10.10.60.147"]
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "root"
}

variable "private_key_path" {
  description = "Path to private SSH key"
  type        = string
  default     = "/home/rajeeve/.ssh/id_rsh"
}

variable "pod_network_cidr" {
  description = "CIDR range for pod network"
  type        = string
  default     = "10.10.60.0/16"
}

variable "k8s_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28.0"
}
