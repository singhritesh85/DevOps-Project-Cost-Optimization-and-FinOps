###################################### Output AWS EKS #############################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eksdemo.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  value       = aws_eks_cluster.eksdemo.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane."
  value       = aws_eks_cluster.eksdemo.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider."
  value       = aws_eks_cluster.eksdemo.identity[0].oidc[0].issuer
}

######################################## Output of EC2 ############################################

output "instance_id" {
  description = "The unique ID of the K8S-Management EC2 instance"
  value       = aws_instance.k8s_management.id
}

output "public_ip" {
  description = "The public IP address of the K8S-Management EC2 instance"
  value       = aws_instance.k8s_management.public_ip
}

output "private_ip" {
  description = "The private IP address of the K8S-Management EC2 instance"
  value       = aws_instance.k8s_management.private_ip
}

####################################### Output of VPC #############################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.test_vpc.id
}

output "vpc_cidr_block" {
  description = "The primary CIDR block associated with the VPC"
  value       = aws_vpc.test_vpc.cidr_block
}

output "vpc_arn" {
  description = "The Amazon Resource Name of the VPC"
  value       = aws_vpc.test_vpc.arn
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.test_vpc.default_security_group_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_subnet[*].id
}

output "public_subnet_cidrs" {
  description = "List of all public subnet CIDR blocks"
  value       = aws_subnet.public_subnet[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of all private subnet CIDR blocks"
  value       = aws_subnet.private_subnet[*].cidr_block
}

####################### Output of Route53 and ACM Certificate ##########################

output "efs_mount_target_ips" {
  value       = aws_efs_mount_target.efs_mount_target.ip_address
  description = "The private IP addresses of the EFS mount targets."
}

output "hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone."
  value       = aws_route53_zone.hosted_zone.zone_id
}

output "hosted_zone_name_servers" {
  description = "The name servers for the Route 53 Hosted Zone."
  value       = aws_route53_zone.hosted_zone.name_servers
}

output "certificate_arn" {
  description = "The AWS ACM Certificate ARN"
  value = aws_acm_certificate.acm_cert.arn
}

output "jenkins_alb_dns_name" {
  description = "DNS Name of Jenkins ALB"
  value = aws_lb.test-application-loadbalancer.dns_name
}

############################ Output of IAM Role ARN to access the SecretStore ###########

output "eso_iam_role_arn" {
  value = aws_iam_role.eso_secrets_role.arn
}
