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

# Tags génériques voir https://spacelift.io/blog/terraform-tags
variable "common_tags" {
  description = "Tags communs à toutes les ressources AWS généré par Terraform"
  type        = map(string)
  default = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "STUDI-ECF"
  }
}