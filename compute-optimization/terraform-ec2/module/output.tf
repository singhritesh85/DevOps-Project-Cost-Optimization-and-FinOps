######################################## Output of EC2 ############################################

output "instance_id" {
  description = "The unique ID of the Dexter-Server EC2 instance"
  value       = aws_instance.dexter_server.id
}

output "ec2_private_ip" {
  description = "The private IP address of the Dexter-Server EC2 instance"
  value       = aws_instance.dexter_server.private_ip
}

output "ec2_elastic_ip" {
  description = "Elastic IP assigned to the EC2 instance"
  value       = aws_eip.eip_associate.public_ip
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
