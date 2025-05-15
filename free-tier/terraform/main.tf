# fixer les versions de plugin, garantir la compatibilité / éviter que le projet ne tourne mal sur une vieille version de Terraform
# version ~> 5.0 car recommandation standard, car :
#  La v5 est stable, largement utilisée en production, Elle supporte tous les services AWS modernes, Elle respecte les bonnes pratiques Terraform v1+
# version de Terraform >= 1.3.0 car Terraform v1.3+ est mature, compatible avec hashicorp/aws v5
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

# Fournisseur : AWS
provider "aws" {
  region = var.region
}

# VPC : réseau avec sous-réseaux privés et publics
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false # ATTENTION : NAT Gateway payantes (même dans free tier) : permet instances dans subnet privé l'accès à Internet (ex : télécharger des mises à jour)
  single_nat_gateway = true # 1 seule NAT Gateway créée dans une seule AZ (réduire les coûts). Les sous-réseaux privés des autres AZs redirigeront leur trafic vers elle via des routes.
}

# Cluster Kubernetes EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

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