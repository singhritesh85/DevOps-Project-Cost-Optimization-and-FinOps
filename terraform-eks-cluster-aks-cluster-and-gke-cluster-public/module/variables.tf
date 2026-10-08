variable "location" {

}

variable "availability_zone" {

}

variable "static_dynamic" {

}

########################################## variables for GCP Resources #########################################################

variable "project_name" {

}

variable "gcp_region" {

}

variable "prefix" {

}

variable "ip_range_subnet" {

}

variable "min_master_version" {

}

variable "node_version" {

}

variable "master_ip_range" {

}

variable "pods_ip_range" {

}

variable "services_ip_range" {

}

variable "ip_public_range_subnet" {

}

variable "machine_type" {

}

variable "env" {

}

####################################################### Variables to create Azure AKS Cluster #########################################################

variable "kubernetes_version_aks" {

}

variable "action_group_shortname" {

}

variable "vm_size" {

}

variable "email_address" {

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
