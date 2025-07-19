output "vpc_id" {
  description = "ID du VPC créé"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Liste des subnets publics"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Liste des subnets privés"
  value       = module.vpc.private_subnets
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint de l'API du cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  description = "Certificat d'autorité pour accéder au cluster (kubeconfig)"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_oidc_issuer_url" {
  description = "URL de l'OIDC issuer du cluster (pour IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_node_group_name" {
  description = "Nom du node group EKS"
  value       = module.eks.eks_managed_node_groups["default"].node_group_id
}

output "eks_node_group_iam_role_arn" {
  description = "ARN du rôle IAM attaché aux nodes EKS"
  value       = module.eks.eks_managed_node_groups["default"].iam_role_arn
}

output "ecr_repository_springboot_url" {
  description = "URL du dépôt ECR pour Spring Boot"
  value       = aws_ecr_repository.springboot.repository_url
}

output "ecr_repository_frontend_admin_url" {
  description = "URL du dépôt ECR pour le frontend admin"
  value       = aws_ecr_repository.frontend_admin.repository_url
}

output "ecr_repository_frontend_public_url" {
  description = "URL du dépôt ECR pour le frontend public"
  value       = aws_ecr_repository.frontend_public.repository_url
}

output "api_gateway_url" {
  description = "URL publique de l'API Gateway HTTP"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}