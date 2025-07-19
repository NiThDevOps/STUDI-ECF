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
