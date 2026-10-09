output "aws_ec2_eks_storageoptimization_iam_role_arn_for_karpenter_efs_s3_details" {
  description = "Details for AWS EC2, EKS, VPC, IAM Role ARN for Karpenter, EFS, S3"
  value       = module.aws_eks_storageoptimization 
  sensitive   = true
}
