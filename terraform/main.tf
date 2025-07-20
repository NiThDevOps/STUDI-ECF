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
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::903479130308:role/GitHubActionsDeployRole"
  }
}