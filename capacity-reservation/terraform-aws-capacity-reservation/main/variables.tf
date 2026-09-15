############################################################# Variables for AWS Resources Prefix ##################################################

variable "prefix" {
  description = "Provide the prefix used for the project"
  type        = string
}

############################################################### Variables for VPC ##################################################################

variable "region" {
  type        = string
  description = "Provide the AWS Region into which EKS Cluster to be created"
}

variable "vpc_cidr" {
  description = "Provide the CIDR for VPC"
  type        = string
  #default = "10.10.0.0/16"
}

variable "private_subnet_cidr" {
  description = "Provide the cidr for Private Subnet"
  type        = list(any)
  #default = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "public_subnet_cidr" {
  description = "Provide the cidr of the Public Subnet"
  type        = list(any)
  #default = ["10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"]
}

data "aws_partition" "amazonwebservices" {
}

data "aws_region" "reg" {
}

data "aws_availability_zones" "azs" {
}

data "aws_caller_identity" "G_Duty" {
}

variable "igw_name" {
  description = "Provide the Name of Internet Gateway"
  type        = string
  #default = "test-IGW"
}

variable "natgateway_name" {
  description = "Provide the Name of NAT Gateway"
  type        = string
  #default = "EKS-NatGateway"
}

variable "vpc_name" {
  description = "Provide the Name of VPC"
  type        = string
  #default = "test-vpc"
}

variable "env" {
  type        = list(any)
  description = "Provide the Environment for EKS Cluster and NodeGroup"
}

########################################### variables to launch EC2 ############################################################

variable "instance_count" {
  description = "Provide the Instance Count"
  type        = number
}

variable "instance_type" {
  type        = list(any)
  description = "Provide the Instance Type EKS Worker Node"
}

variable "provide_ami" {
  description = "Provide the AMI ID for the EC2 Instance"
  type        = map(any)
}

#variable "vpc_security_group_ids" {
#  description = "Provide the security group Ids to launch the EC2"
#  type = list
#}

#variable "subnet_id" {
#  description = "Provide the Subnet ID into which EC2 to be launched"
#  type = string
#}

variable "cidr_blocks" {
  description = "Provide the CIDR Block range"
  type        = list(any)
}

variable "kms_key_id" {
  description = "Provide the KMS Key ID to Encrypt EBS"
  type        = string
}

variable "name" {
  description = "Provide the name of the EC2 Instance"
  type        = string
}
