module "aws_eks_multiarchitecture" {

  source = "../module"

############################################################# Variables for AWS Resources Prefix ###################################################

  prefix = var.prefix 

############################################################### Variables for VPC ##################################################################

  vpc_cidr = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
  igw_name = var.igw_name
  natgateway_name = var.natgateway_name
  vpc_name = var.vpc_name
  env = var.env[0]

############################################################ Provide parameter for EKS ###########################################################

  eks_cluster = var.eks_cluster
  eks_iam_role_name = var.eks_iam_role_name
  node_group_name = var.node_group_name
  eks_nodegrouprole_name = var.eks_nodegrouprole_name
  launch_template_name = var.launch_template_name
  instance_type = var.instance_type
  disk_size = var.disk_size
  capacity_type = var.capacity_type
  ami_type = var.ami_type
  release_version = var.release_version 
  kubernetes_version = var.kubernetes_version
  ebs_csi_name = var.ebs_csi_name
  ebs_csi_version = var.ebs_csi_version[0]
  node_monitoring_version = var.node_monitoring_version[0]
  csi_snapshot_controller_version = var.csi_snapshot_controller_version[0]
  addon_version_guardduty = var.addon_version_guardduty[0]
  addon_version_kubeproxy = var.addon_version_kubeproxy[0]
  addon_version_vpc_cni = var.addon_version_vpc_cni[0]
  addon_version_coredns = var.addon_version_coredns[0]
  addon_version_observability = var.addon_version_observability[0]
  addon_version_podidentityagent = var.addon_version_podidentityagent[0]
  addon_version_metrics_server = var.addon_version_metrics_server[0]

###########################To Launch EC2###################################

  instance_count = var.instance_count
  provide_ami    = var.provide_ami["us-east-2"]
  #  vpc_security_group_ids = var.vpc_security_group_ids
  cidr_blocks = var.cidr_blocks
  #  subnet_id = var.subnet_id
  kms_key_id = var.kms_key_id
  name       = var.name  

##########################To Encrypt EKS Backup ###########################

  backup_kms_key_arn = var.backup_kms_key_arn

}
