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
  source  = "terraform-aws-modules/vpc/aws" # module maintenu par la communauté Terraform AWS Modules
  version = "5.21.0" # dernière version stable disponible
  name = var.vpc_name
  cidr = "10.0.0.0/16"
  azs             = ["${var.region}a", "${var.region}b"] # 2 AZs minimum pour tolérance de panne
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true # ATTENTION : NAT Gateway payantes (même dans free tier) : permet l'accès à Internet pour les instances dans subnet privé  (ex : télécharger des mises à jour)
  tags = var.common_tags
  }

# Cluster Kubernetes EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws" # module maintenu par la communauté Terraform AWS Modules
  version         = "20.36.0" # dernière version stable disponible
  cluster_name    = var.cluster_name
  cluster_version = "1.32" # dernière version disponible dans le support amazon EKS. source : https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/kubernetes-versions.html 
  vpc_id     = module.vpc.vpc_id # pour créer le module eks, on a besoin des paramètres réseaux provenant du module vpc
  subnet_ids = module.vpc.private_subnets # pour créer le module eks, on a besoin des paramètres réseaux provenant du module vpc
  eks_managed_node_groups = { # voir "https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/managed-node-groups.html" utilisation d'un seul node pour rester dans le free tier
    default = {
      # Mode DEV (ECF / free tier / démo) —> pour le passage du projet. pas de HA, auto scaling, puisqu'un seul node. L'interet c'est qu'avec managed node groups, AWS gère les mises à jour et la maintenance.
      desired_capacity = 1
      max_capacity     = 1
      min_capacity     = 1
      instance_types   = ["t3.micro"]
    }
  }
  tags = var.common_tags
  enable_irsa = true
}

resource "aws_ecr_repository" "springboot" { # voir "https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/ecr_repository"
  name                 = "hello-springboot"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.common_tags
}