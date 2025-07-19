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
      # 12/06/2025 : augmentation du nombre de EC2 car limité à 4 pods par instance et déjà 4 pods système utilisé donc impossible d'ajouter un pod avec l'appli java spring boot
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.micro"]
    }
  }
  tags = var.common_tags
  enable_irsa = true
}