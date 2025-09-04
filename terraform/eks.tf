module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  # Accès API
  cluster_endpoint_public_access = true
  # cluster_endpoint_public_access_cidrs = ["X.X.X.X/32"] # optionnel : restreindre à ton IP

  # Admin & IRSA
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  # Node groups
  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.small"]
  }

  eks_managed_node_groups = {
    default = {
      name         = "eks-nodegroup-infoline"
      desired_size = 2
      min_size     = 2
      max_size     = 4
    }
  }

  ############################################
  # NOUVEAU : installation de l'addon EBS CSI
  ############################################
  # Le rôle IAM "aws_iam_role.ebs_csi" est défini dans ebs_csi.tf
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi.arn
    }
  }

  tags = var.common_tags
}

# Récupération automatique du rôle IAM généré par le node group
data "aws_iam_role" "nodegroup_role" {
  name = module.eks.eks_managed_node_groups["default"].iam_role_name
}

# Attachement de la politique ECR read-only pour que les nodes puissent pull des images
resource "aws_iam_role_policy_attachment" "ecr_readonly_for_nodes" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.nodegroup_role.name
}
