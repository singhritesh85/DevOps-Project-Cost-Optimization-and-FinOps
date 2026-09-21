output "aws_ec2_eks_multiarchitecture_iam_role_arn_details" {
  description = "Details for AWS EC2, EKS, VPC, IAM Role ARN"
  value       = module.aws_eks_multiarchitecture 
  sensitive   = true
}
