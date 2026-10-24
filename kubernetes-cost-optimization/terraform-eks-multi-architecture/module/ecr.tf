############################################# Elastic Container Registry (ECR) #####################################################

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "${var.prefix}-ecr-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true ### Automatically scan container images for vulnerabilities on push
  }

  tags = {
    Name        = "${var.prefix}-ecr-repo"
    Environment = var.env
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}
