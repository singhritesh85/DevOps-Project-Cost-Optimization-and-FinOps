module "eks_cluster_aks_cluster_and_standard_gke_cluster" {
  source = "../module"

  prefix = var.prefix
  location = var.location[1]
  env = var.env[0]
  availability_zone = var.availability_zone[0]
  static_dynamic = var.static_dynamic 

############################################### For GCP Resources ##############################################################

  project_name = var.project_name
  gcp_region = var.gcp_region[3]
  ip_range_subnet = var.ip_range_subnet
  master_ip_range = var.master_ip_range
  min_master_version = var.min_master_version[0]
  node_version = var.node_version[0]
  pods_ip_range = var.pods_ip_range
  services_ip_range = var.services_ip_range
  ip_public_range_subnet = var.ip_public_range_subnet
  machine_type = var.machine_type

################################ To create Azure AKS Cluster #################################

  kubernetes_version_aks = var.kubernetes_version_aks[15]
  action_group_shortname = var.action_group_shortname
  vm_size = var.vm_size[0]
  email_address = var.email_address  

############################################################### Variables for VPC ##################################################################

  vpc_cidr = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
  igw_name = var.igw_name
  natgateway_name = var.natgateway_name
  vpc_name = var.vpc_name

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

}
