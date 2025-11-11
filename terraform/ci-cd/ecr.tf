resource "aws_ecr_repository" "pcfactory" {
  name                 = "pcfactory-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "pcfactory-app"
    Environment = var.environment
    Project     = "PCFactory"
  }
}

resource "aws_ecr_lifecycle_policy" "pcfactory" {
  repository = aws_ecr_repository.pcfactory.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
