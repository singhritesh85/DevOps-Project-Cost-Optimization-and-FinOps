module "aws_ec2" {

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

###########################To Launch EC2###################################

  instance_count = var.instance_count
  instance_type  = var.instance_type[5]   ###var.instance_type[2]  ### t3.2xlarge has 8 vCPUs and t3.medium has 2 vCPUs.
  provide_ami    = var.provide_ami["us-east-2"]
  #  vpc_security_group_ids = var.vpc_security_group_ids
  cidr_blocks = var.cidr_blocks
  #  subnet_id = var.subnet_id
  kms_key_id = var.kms_key_id
  name       = var.name  

}
