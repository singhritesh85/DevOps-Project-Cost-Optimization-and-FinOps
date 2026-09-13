##################################### Variables for RDS ########################################################

variable "identifier" {

}
variable "db_subnet_group_name" {

}
#variable "read_replica_identifier" {

#}
variable "allocated_storage" {

}
variable "max_allocated_storage" {

}
#variable "read_replica_max_allocated_storage" {

#}
variable "storage_type" {

}
#variable "read_replica_storage_type" {

#}
variable "engine" {

}
variable "engine_version" {

}
variable "instance_class" {

}
#variable "read_replica_instance_class" {

#}
variable "rds_db_name" {

}
variable "username" {

}
variable "password" {

}
variable "parameter_group_name" {

}
variable "multi_az" {

}
#variable "read_replica_multi_az" {

#}
#variable "final_snapshot_identifier" {

#}
variable "skip_final_snapshot" {

}
#variable "copy_tags_to_snapshot" {

#}
variable "availability_zone" {

}
variable "publicly_accessible" {

}
#variable "read_replica_vpc_security_group_ids" {

#}
#variable "backup_retention_period" {

#}
variable "kms_key_id_rds" {

}
#variable "read_replica_kms_key_id" {

#}
variable "monitoring_role_arn" {

}
variable "enabled_cloudwatch_logs_exports" {

}

##################################### Variables for VPC ########################################################

variable "vpc_cidr"{

}

variable "private_subnet_cidr"{

}

variable "public_subnet_cidr"{

}

variable "igw_name" {

}

variable "vpc_name" {

}

data "aws_availability_zones" "azs" {

}

##################################### Variables for ALB and ASG ################################################
variable "prefix" {

}
variable "alb_tg_name" {

}
variable "sg_name" {

}
variable "sg_description" {

}
variable "cidr_blocks" {

}
variable "s3_bucket_exists" {

}
variable "access_log_bucket" {

}
variable "alb_name" {

}
variable "internal_external" {

}
variable "instance_port" {

}
variable "instance_protocol" {

}
variable "loadbalancer_type" {

}
variable "enable_deletion_protection" {

}
variable "target_type" {

}
variable "healthy_threshold" {

}
variable "interval" {

}
variable "unhealthy_threshold" {

}
variable "timeout" {

}
variable "healthcheck_path" {

}
variable "healthcheck_protocol" {

}
variable "ssl_policy" {

}
#variable "certificate_arn" {

#}
variable "kms_key_id" {

}
variable "launch_template_name" {

}
variable "AMI_ID" {

}
variable "instance_type" {

}
variable "iam_instance_profile" {

}
variable "key_name" {

}
variable "associate_public_ip_address" {

}
variable "enable_monitoring" {

}
variable "ebs_optimized" {

}
variable "placement_tenancy" {

}
variable "asg_name" {
 
}
variable "min_size" {

}
variable "max_size" {

}
variable "desired_capacity" {

}
variable "default_cooldown" {

}
variable "service_linked_role_arn" {

}
variable "health_check_grace_period" {

}
variable "health_check_type" {

}
variable "force_delete" {

}
variable "treat_missing_data" {

}
variable "sns_topic_name" {

}
variable "env" {

}

####################################################### Variables to create Route 53 Hosted Zone #######################################################

variable "name" {

}

######################################################## Variables for Jenkins #########################################################################

variable "provide_ami" {

}

