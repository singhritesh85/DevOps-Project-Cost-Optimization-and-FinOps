output "aws_ec2_eks_multiarchitecture_iam_role_arn_jenkins_alb_efs_route53_acm_certificate_details" {
  description = "Details for AWS EC2, EKS, VPC, IAM Role ARN, Jenkins ALB, EFS,Route53, ACM Certificate ARN"
  value       = module.aws_eks_multiarchitecture 
  sensitive   = true
}
