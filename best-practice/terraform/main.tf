# fixer les versions de plugin, garantir la compatibilité / éviter que le projet ne tourne mal sur une vieille version de Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # utilise la dernière version 5.X disponible. version 6 en bêta
    }
  }

  required_version = ">= 1.12.0" # dernière version stable disponible
}

# Fournisseur : AWS
provider "aws" {
  region = var.region
}

# VPC : réseau avec sous-réseaux privés et publics
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0" # dernière version stable disponible

  name = "infoline-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false # ATTENTION : NAT Gateway payantes (même dans free tier) : permet instances dans subnet privé l'accès à Internet (ex : télécharger des mises à jour)
  # single_nat_gateway = true # 1 seule NAT Gateway créée dans une seule AZ (réduire les coûts). Les sous-réseaux privés des autres AZs redirigeront leur trafic vers elle via des routes.
}

# Cluster Kubernetes EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0" # dernière version stable disponible

  cluster_name    = var.cluster_name
  cluster_version = "1.32" # dernière version disponible dans le support amazon EKS. source : https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/kubernetes-versions.html 

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_capacity = 1
      max_capacity     = 1
      min_capacity     = 1
      instance_types   = ["t3.micro"]
    }
  }

  enable_irsa = true
}