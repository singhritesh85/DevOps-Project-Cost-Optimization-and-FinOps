############################################################# Variables for AWS Resources Prefix ##################################################

variable "prefix" {

}

############################################################# Variables for AWS VPC ###############################################################

variable "vpc_cidr"{

}

variable "private_subnet_cidr"{

}

variable "public_subnet_cidr"{

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

}

variable "natgateway_name" {

}

variable "vpc_name" {

}

variable "env" {

}

################################################################ variables to launch EC2 ################################################################

variable "instance_count" {

}

variable "instance_type" {

}

variable "provide_ami" {

}

#variable "vpc_security_group_ids" {

#}

#variable "subnet_id" {

#}

variable "kms_key_id" {

}

variable "cidr_blocks" {

}

variable "name" {

}

