module "jenkins_self_healing" {

  source = "../module"
  cidr_blocks = var.cidr_blocks
  s3_bucket_exists = var.s3_bucket_exists
  access_log_bucket = var.access_log_bucket
  env = var.env[0]
  vpc_name = var.vpc_name
#  public_subnets = var.public_subnets
#  private_subnets = var.private_subnets
#  vpc_id = var.vpc_id
  ssl_policy = var.ssl_policy[0]
  certificate_arn = var.certificate_arn
  kms_key_id = var.kms_key_id
  service_linked_role_arn = var.service_linked_role_arn
  provide_ami = var.provide_ami["us-east-2"]
  instance_type = var.instance_type
  name = var.name
}
