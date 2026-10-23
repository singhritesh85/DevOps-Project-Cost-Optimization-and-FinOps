############################ Security Group for Interface Endpoints (Allowing EKS nodes to connect) ################################
resource "aws_security_group" "vpc_endpoints" {
  name          = "${var.prefix}-eks-vpc-endpoints-sg"
  description   = "Security group for EKS VPC endpoints"
  vpc_id        = aws_vpc.test_vpc.id

#  ingress {
#    description     = "Allow HTTPS 443 from EKS control plane and worker nodes"
#    from_port       = 443
#    to_port         = 443
#    protocol        = "tcp"
#    security_groups = [aws_eks_cluster.eksdemo.vpc_config[0].cluster_security_group_id]
#  }

  ingress {
    description = "Allow HTTPS 443 from entire VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################### S3 Gateway Endpoint ###########################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.test_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.reg.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_route_table_1.id, aws_route_table.private_route_table_2.id, aws_route_table.private_route_table_3.id]

  tags = {
    Name = "${var.prefix}-s3-gateway-endpoint"
  }
}

##################################################### ECR API Interface Endpoint ###################################################
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.test_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.reg.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-ecr-api-endpoint"
  }
}

########################################## ECR DKR Interface Endpoint (Required for pulling image layers) ##########################
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.test_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.reg.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-ecr-dkr-endpoint"
  }
}

################################## EFS Interface Endpoint (Required if pods mount EFS Persistent Volumes) #########################
resource "aws_vpc_endpoint" "efs" {
  vpc_id              = aws_vpc.test_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.reg.region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-efs-endpoint"
  }
}
