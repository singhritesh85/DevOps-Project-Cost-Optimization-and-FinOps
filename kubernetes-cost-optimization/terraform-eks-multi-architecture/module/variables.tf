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

################################################################ Variables for EKS ##########################################################################

variable "eks_cluster" {

}

variable "eks_iam_role_name" {

}

variable "node_group_name" {

}

variable "eks_nodegrouprole_name" {

}

variable "launch_template_name" {

}

variable "instance_type" {

}

#variable "eks_ami_id" {

#}

variable "disk_size" {

}

variable "capacity_type" {

}

variable "ami_type" {

}

variable "release_version" {

}

variable "kubernetes_version" {

}

variable "node_monitoring_version" {

}

variable "ebs_csi_name" {

}

variable "ebs_csi_version" {

}

variable "csi_snapshot_controller_version" {

}

variable "addon_version_guardduty" {

}

variable "addon_version_kubeproxy" {

}

variable "addon_version_vpc_cni" {

}

variable "addon_version_coredns" {

}

variable "addon_version_observability" {

}

variable "addon_version_podidentityagent" {

}

variable "addon_version_metrics_server" {

}

################################################################ variables to launch EC2 ################################################################

variable "instance_count" {

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

########################################################## variables for Backup ##################################################

variable "backup_kms_key_arn" {

}
