terraform {
  required_version = ">= 1.12.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}

# Permet de passer un kubeconfig explicite via TF_VAR_kubeconfig_path
variable "kubeconfig_path" {
  description = "Path to kubeconfig (defaults to ~/.kube/config)"
  type        = string
  default     = ""
}

provider "kubernetes" {
  config_path = var.kubeconfig_path != "" ? var.kubeconfig_path : pathexpand("~/.kube/config")
}
