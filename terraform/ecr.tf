resource "aws_ecr_repository" "springboot" { # voir "https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/ecr_repository"
  name                 = "hello-springboot"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.common_tags
}
resource "aws_ecr_repository" "frontend_admin" {
  name                 = "frontend-admin"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.common_tags
}

resource "aws_ecr_repository" "frontend_public" {
  name                 = "frontend-public"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.common_tags
}