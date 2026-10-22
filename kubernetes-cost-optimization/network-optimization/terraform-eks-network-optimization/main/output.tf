output "aws_ec2_eks_storageoptimization_iam_role_arn_for_karpenter_efs_s3_route53_nameservers_and_acm_Certificate_details" {
  description = "Details for AWS EC2, EKS, VPC, IAM Role ARN for Karpenter, EFS, S3, Route53 Hostedzone Nameservers and ACM Certificate"
  value       = module.aws_eks_networkoptimization 
  sensitive   = true
}
