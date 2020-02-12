resource "aws_ecr_repository" "belly-ecr" {
  name = var.ecr-name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}