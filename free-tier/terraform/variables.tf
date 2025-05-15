variable "region" {
  description = "La région AWS"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  default     = "ecf-eks-cluster"
}