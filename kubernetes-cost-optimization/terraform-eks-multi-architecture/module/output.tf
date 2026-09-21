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

