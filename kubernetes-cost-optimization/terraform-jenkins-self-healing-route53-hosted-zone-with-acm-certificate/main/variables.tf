variable "region" {
  description = "Provide the AWS Region into which the Resources to be created"
  type = string
}  

variable "cidr_blocks" {
  description = "Provide the CIDR Block range"
  type = list
}

variable "s3_bucket_exists" {
  description = "Create S3 bucket only if doesnot exists."
  type = bool
}

variable "service_linked_role_arn" {
  description = "Provide the service linked role arn"
  type = string
}

variable "access_log_bucket" {
  description = "S3 bucket to capture Application LoadBalancer"
  type = string
}

variable "env" {
  type = list
  description = "Provide the Environment for AWS Resources to be created"
}

variable "vpc_name" {
  description = "Provide the VPC Name"
  type = string
}

#variable "public_subnets" {
#  description = "Provide the Public Subnet IDs of VPC"
#  type = list
#}

#variable "private_subnets" {
#  description = "Provide the Private Subnet IDs of VPC"
#  type = list
#}

#variable "vpc_id" {
#  description = "Provide the VPC ID"
#  type = string
#}

variable "ssl_policy" {
  description = "Select the SSl Policy for the Application Loadbalancer"
  type = list
}

variable "certificate_arn" {
  description = "Provide the SSL Certificate ARN from AWS Certificate Manager"
  type = string
}

variable "provide_ami" {
  description = "Provide the AMI ID for the EC2 Instance"
  type = map
}

variable "kms_key_id" {
  description = "Provide the ARN for KMS ID to encrypt EBS"
  type = string
}

variable "instance_type" {
  type = list
  description = "Provide the Instance Type EKS Worker Node" 
}

variable "name" {
  description = "Provide the name of the Route53 Hosted Zone"
  type = string
}
