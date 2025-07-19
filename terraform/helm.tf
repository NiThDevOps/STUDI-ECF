# déploiement des charts Helm dans le cluster Kubernetes
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# déploiement de l’Ingress Controller NGINX (agit comme une “passerelle HTTP” pour le cluster)

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"
  version    = "4.10.0"

  set {
    name  = "controller.service.type" # IP publique automatiquement pour ton Ingress
    value = "LoadBalancer"
  }

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }

  depends_on = [module.eks]
}

resource "helm_release" "java_api" {
  name       = "java-api"
  chart      = "${path.module}/../charts/java-api"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = aws_ecr_repository.springboot.repository_url
  }
}

resource "helm_release" "frontend_admin" {
  name       = "frontend-admin"
  chart      = "${path.module}/../charts/frontend-admin"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = aws_ecr_repository.frontend_admin.repository_url
  }
}

resource "helm_release" "frontend_public" {
  name       = "frontend-public"
  chart      = "${path.module}/../charts/frontend-public"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = aws_ecr_repository.frontend_public.repository_url
  }
}

resource "helm_release" "infoline_ingress" {
  name       = "infoline-ingress"
  chart      = "${path.module}/../charts/infoline-ingress"
  namespace  = "default"

  depends_on = [
    helm_release.nginx_ingress,
    helm_release.java_api,
    helm_release.frontend_admin,
    helm_release.frontend_public
  ]
}