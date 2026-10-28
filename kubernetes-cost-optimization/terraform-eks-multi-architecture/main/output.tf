output "aws_ec2_eks_costoptimization_iam_role_arn_for_karpenter_route53_nameservers_and_acm_Certificate_details" {
  description = "Details for AWS EC2, EKS, VPC, IAM Role ARN for Karpenter, Route53 Hostedzone Nameservers and ACM Certificate"
  value       = module.aws_eks_costoptimization
  sensitive   = true
}
