variable "region" {
  description = "région AWS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "infoline-eks-cluster"
}

variable "vpc_name" {
  description = "Nom du VPC"
  type        = string
  default     = "infoline-vpc"
}
