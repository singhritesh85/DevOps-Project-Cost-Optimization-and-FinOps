output "aws_vpc_and_ec2_details" {
  description = "Details for AWS EC2"
  value       = module.aws_ec2 
#  sensitive   = true
}
