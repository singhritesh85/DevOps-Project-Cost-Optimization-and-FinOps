############################################### RDS DB Instance Parameters ###############################################

  db_instance_count = 1
  region = "us-east-2"
  identifier = "dbinstance-1"   
  db_subnet_group_name = "rds-subnetgroup"        ###  postgresql-subnetgroup 
#  read_replica_identifier = "dbinstance-readreplica-1"
  allocated_storage = 20
  max_allocated_storage = 100
#  read_replica_max_allocated_storage = 100
  storage_type = ["gp2", "gp3", "io1", "io2"]
#  read_replica_storage_type = ["gp2", "gp3", "io1", "io2"]
  engine = ["mysql", "mariadb", "mssql", "postgres"]
  engine_version = ["5.7.44", "8.0.33", "8.0.35", "8.0.36", "8.4.9", "10.4.30", "10.5.20", "10.11.6", "10.11.7", "13.00.6435.1.v1", "14.00.3421.10.v1", "15.00.4365.2.v1", "14.9", "14.10", "14.11", "14.20", "15.5", "16.1"] ### For postgresql select version = 14.20 and for MySQL select version = 5.7.44
  instance_class = ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge"]
#  read_replica_instance_class = ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge"]
  rds_db_name = "jwt"   ###"mydb"
  username = "adminuser"   ### For MySQL select username as admin and For PostgreSQL select username as postgres
  password = "Admin123"          ### "Sonar123" use this password for PostgreSQL
  parameter_group_name = ["default.mysql5.7", "default.mysql8.4", "default.postgres14"]
  multi_az = ["false", "true"]   ### select between true or false
#  read_replica_multi_az = false   ### select between true or false
#  final_snapshot_identifier = "database-1-final-snapshot-before-deletion"   ### Here I am using it for demo and not taking final snapshot while db instance is deleted
  skip_final_snapshot = ["true", "false"]
#  copy_tags_to_snapshot = true   ### Select between true or false
  availability_zone = ["us-east-2a", "us-east-2b", "us-east-2c"]
  publicly_accessible = ["true", "false"]  #### Select between true or false
#  read_replica_vpc_security_group_ids = ["sg-038XXXXXXXXXXXXc291", "sg-a2XXXXXXca"]
#  backup_retention_period = 7   ### For Demo purpose I am not creating any db backup.
  kms_key_id_rds = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#  read_replica_kms_key_id = "arn:aws:kms:us-east-2:027XXXXXXX06:key/20XXXXXXf3-aXXc-4XXd-9XX4-24XXXXXXXXXX17"  ### I am not using any read replica here.
  monitoring_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/rds-monitoring-role"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]   ### ["audit", "error", "general", "slowquery"]  for MySQL

########################################## Parameters for VPC #############################################################

vpc_cidr = "10.10.0.0/16"
private_subnet_cidr = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
public_subnet_cidr = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
igw_name = "dexter-IGW"
vpc_name = "dexter-vpc"

##########################################Parameters to create ALB and ASG################################################

access_log_bucket = "s3bucketcapturealblog"
prefix = "application_loadbalancer_log_folder"
alb_tg_name = "autoscale-tg"
sg_name = "alb-test-sg"
sg_description = "Security Group for ALB for Autoscaling"
s3_bucket_exists = false
cidr_blocks = ["0.0.0.0/0"]       ### You can use the VPN IP here as provided by your organisation. 
alb_name = "test-alb-autoscale"
internal_external = false
instance_port = 80
instance_protocol = "HTTP"
loadbalancer_type = ["application", "network"]
enable_deletion_protection = false
target_type = ["instance", "ip", "lambda"]
healthy_threshold = 2
interval = 30
unhealthy_threshold = 2
timeout = 5
healthcheck_path = "/"
healthcheck_protocol = "HTTP"
ssl_policy = ["ELBSecurityPolicy-TLS13-1-2-2021-06", "ELBSecurityPolicy-2016-08", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01", "ELBSecurityPolicy-TLS-1-2-Ext-2018-06", "ELBSecurityPolicy-FS-2018-06", "ELBSecurityPolicy-2015-05"]
#certificate_arn = "arn:aws:acm:us-east-2:02XXXXXXXXX6:certificate/fXXXXXXXXe-bXX3-4XXd-8XX0-2XXXXXXXXXX9"
kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
launch_template_name = "Spot-Instances-LaunchTemplate"
instance_type = ["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge"]
iam_instance_profile = "AmazonS3FullAccess"
key_name = ["testkey"]
associate_public_ip_address = false   ###true
enable_monitoring = true
ebs_optimized = [true, false]
placement_tenancy = ["default", "dedicated"]
asg_name = "Autoscaling-Group-for-Spot-Instances"
min_size = 1
max_size = 4
desired_capacity = 2
default_cooldown = 100
service_linked_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
health_check_grace_period = 100
health_check_type = ["EC2", "ELB"]
force_delete = true
treat_missing_data = ["missing", "ignore", "breaching", "notBreaching"]
sns_topic_name = "MyTopic"

env = ["dev", "stage", "prod"]

################################################### Parameters to create Route53 Hosted Zone #######################################################

name = "singhritesh85.com"

############################################################### Parameters for Jenkins #############################################################

provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-048f644e868baa0e8"   ###"ami-0c6ac5f2fed2981b0"        ###"ami-09256c524fab91d36"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
