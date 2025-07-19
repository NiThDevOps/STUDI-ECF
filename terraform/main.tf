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

# déploiement du ingress-nginx (ingress controller = pod déployé - écoute requête http/https - applique les règles définis dans ingress et redirige vers les bons services) par Terraform
# voir (https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}