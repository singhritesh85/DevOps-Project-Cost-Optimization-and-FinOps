module "autoscale_packer" {
source = "../module"

############################################### For RDS ##############################################################

  count = var.db_instance_count
  identifier = var.identifier
  db_subnet_group_name = var.db_subnet_group_name
#  read_replica_identifier = var.read_replica_identifier  ###  read_replica_identifier = "${var.read_replica_identifier}-${count.index + 1}"
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
#  read_replica_max_allocated_storage = var.read_replica_max_allocated_storage
  storage_type = var.storage_type[0]
#  read_replica_storage_type = var.read_replica_storage_type
  engine = var.engine[0]             ### var.engine[0]  use for MySQL
  engine_version = var.engine_version[4]       ### var.engine_version[0]  use for MySQL
  instance_class = var.instance_class[0]
#  read_replica_instance_class = var.read_replica_instance_class
  rds_db_name = var.rds_db_name
  username = var.username
  password = var.password
  parameter_group_name = var.parameter_group_name[1]
  multi_az = var.multi_az[0]
#  read_replica_multi_az = var.read_replica_multi_az
#  final_snapshot_identifier = var.final_snapshot_identifier
  skip_final_snapshot = var.skip_final_snapshot[0]
#  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  availability_zone = var.availability_zone[0]  ### It should not be enabled for Multi-AZ option, If it is not enabled for Single DB Instance then it's value will be taken randomly.
  publicly_accessible = var.publicly_accessible[1]
#  read_replica_vpc_security_group_ids = var.read_replica_vpc_security_group_ids
#  backup_retention_period = var.backup_retention_period
  kms_key_id_rds = var.kms_key_id_rds
#  read_replica_kms_key_id = var.read_replica_kms_key_id
  monitoring_role_arn = var.monitoring_role_arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports


############################################### For VPC ##############################################################

  vpc_cidr = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
  igw_name = var.igw_name
  vpc_name = var.vpc_name

############################################### For ALB and ASG ######################################################

access_log_bucket = var.access_log_bucket
prefix = var.prefix
sg_name = var.sg_name
sg_description = var.sg_description
cidr_blocks = var.cidr_blocks
s3_bucket_exists = var.s3_bucket_exists
alb_name = var.alb_name
alb_tg_name = var.alb_tg_name
internal_external = var.internal_external
loadbalancer_type = var.loadbalancer_type[0]
enable_deletion_protection = var.enable_deletion_protection
instance_port = var.instance_port
instance_protocol = var.instance_protocol
target_type = var.target_type[0]
healthy_threshold = var.healthy_threshold
interval = var.interval
unhealthy_threshold = var.unhealthy_threshold
timeout = var.timeout
healthcheck_path = var.healthcheck_path
healthcheck_protocol = var.healthcheck_protocol
ssl_policy = var.ssl_policy[0]
#certificate_arn = var.certificate_arn
kms_key_id = var.kms_key_id
launch_template_name = var.launch_template_name
#launchconfiguration_name = var.launchconfiguration_name
AMI_ID = var.AMI_ID
instance_type = var.instance_type
iam_instance_profile = var.iam_instance_profile
key_name = var.key_name[0]
associate_public_ip_address = var.associate_public_ip_address
enable_monitoring = var.enable_monitoring
ebs_optimized = var.ebs_optimized[0]
placement_tenancy = var.placement_tenancy[0]
asg_name = var.asg_name
min_size = var.min_size
max_size = var.max_size
desired_capacity = var.desired_capacity
default_cooldown = var.default_cooldown
service_linked_role_arn = var.service_linked_role_arn
health_check_grace_period = var.health_check_grace_period
health_check_type = var.health_check_type[1]
force_delete = var.force_delete
treat_missing_data = var.treat_missing_data[0]
sns_topic_name = var.sns_topic_name

env = var.env[0]

############################################ For Route53 Hosted Zone ############################################

name = var.name

############################################## Form Jenkins #####################################################

provide_ami = var.provide_ami["us-east-2"]

}
