#S3 Bucket to capture ALB access logs
resource "aws_s3_bucket" "s3_bucket" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = var.access_log_bucket

  force_destroy = true

  tags = {
    Environment = var.env
  }
}

#S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3bucket_encryption" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

#data "aws_caller_identity" "G_Duty" {
#}

#IAM Policy allowing read/write access to your target S3 bucket
resource "aws_iam_policy" "s3_csi_driver_policy" {
  name        = "S3CSIDriverPolicy-${var.env}"
  description = "Policy for Mountpoint S3 CSI Driver to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = "arn:aws:s3:::${var.access_log_bucket}" 
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "arn:aws:s3:::${var.access_log_bucket}/*" 
      }
    ]
  })
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.s3bucket_encryption]
}

#################################################### Elastic File System (EFS) ########################################################

resource "aws_security_group" "efs_ingress" {
  name        = "efs-ingress-${var.eks_cluster}-${var.env}"
  description = "Allow inbound NFS traffic from private EKS cluster nodes"
  vpc_id      = aws_vpc.test_vpc.id

  # Allow inbound NFS (2049) from the EKS-managed cluster security group
  # (Automatically covers worker nodes, Karpenter nodes, and anything attached to the cluster SG)
  ingress {
    description     = "Allow NFS traffic from EKS Cluster Security Group"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.eksdemo.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "efs-ingress-${var.eks_cluster}-${var.env}"
    Environment = var.env
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_efs_file_system" "eks_storageoptimization_EFS" {
  creation_token   = "eks-storageoptimization-EFS"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Name        = "eks-efs-storageoptimization"
    Environment = var.env
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = length(aws_subnet.private_subnet)
  file_system_id  = aws_efs_file_system.eks_storageoptimization_EFS.id
  subnet_id       = aws_subnet.private_subnet[count.index].id         ###var.public_subnets[0]
  security_groups = [aws_security_group.efs_ingress.id]
}
