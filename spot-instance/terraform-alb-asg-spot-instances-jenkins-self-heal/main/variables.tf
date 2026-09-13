########################################### Variables for RDS #########################################################

variable "region" {
  description = "The region into which to create the RDS"
  type = string
}
variable "identifier" {
  description = "Provide the DB Instance Name"
  type = string
}
variable "db_subnet_group_name" {
  description = "Provide the Name for DB Subnet Group"
  type = string
}
variable "db_instance_count" {
  description = "Provide the number of DB Instances to be launched"
  type = number
}
#variable "read_replica_identifier" {
#  description = "Provide the Read-Replica DB Instance Name"
#  type = string
#}
variable "allocated_storage" {
  description ="Memory Allocated for RDS"
  type = number
}
variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  type = number
}
#variable "read_replica_max_allocated_storage" {
#  description = "The upper limit to which Amazon RDS Read Replica can automatically scale the storage of the DB instance"
#  type = number
#}
variable "storage_type" {
  description = "storage type of RDS"
  type = list
}
#variable "read_replica_storage_type" {
#  description = "storage type of RDS Read Replica"
#  type = string
#}
variable "engine" {
  description = "Engine of RDS"
  type = list
}
variable "engine_version" {
  description = "Engine Version of RDS"
  type = list
}
variable "instance_class" {
  description = "DB Instance Type"
  type = list
}
#variable "read_replica_instance_class" {
#  description = "DB Instance Type of Read Replica"
#  type = list
#}
variable "rds_db_name" {
  description = "Provide the DB Name"
  type = string
}
variable "username" {
  description = "Provide the DB Instance username"
  type = string
}
variable "password" {
  description = "Provide the Password of DB Instance"
  type = string
}
variable "parameter_group_name" {
  description = "Parameter Group Name for RDS"
  type = list
}
variable "multi_az" {
  description = "To enable or disable multi AZ"
  type = list
}
#variable "read_replica_multi_az" {
#  description = "To enable or disable multi AZ"
#  type = list
#}
#variable "final_snapshot_identifier" {
#  description = "Provide the Final Snapshot Name"
#  type = string
#}
variable "skip_final_snapshot" {
  description = "To skip Final Snapshot before deletion"
  type = list
}
#variable "copy_tags_to_snapshot" {
#  description = "Copy Tags to Final Snapshot"
#  type = list
#}
variable "availability_zone" {
  description = "Availabilty Zone of the RDS DB Instance"
  type = list
}
variable "publicly_accessible" {
  description = "To make RDS publicly Accessible or not"
  type = list
}
#variable "read_replica_vpc_security_group_ids" {
#  description = "List of VPC security groups to br associated with RDS Read Replica"
#  type = list
#}
#variable "backup_retention_period" {
#  description = "The days to retain backups for. Must be between 0 and 35"
#  type = list
#}
variable "kms_key_id_rds" {
  description = "ARN of Kms Key Id to encrypt the RDS Volume"
  type = string
}
#variable "read_replica_kms_key_id" {
#  description = "ARN of Kms Key Id to encrypt the RDS Volume of Read Replica"
#  type = string
#}
variable "monitoring_role_arn" {
  description = "ARN of IAM Role to enable enhanced monitoring"
  type = string
}
variable "enabled_cloudwatch_logs_exports" {
  description = "Which type of Logs to enable"
  type = list
}

########################################### Variables for VPC #########################################################
variable "vpc_cidr"{
  description = "Provide the CIDR for VPC"
  type = string
}

variable "private_subnet_cidr"{
  description = "Provide the cidr for Private Subnet of VPC"
  type = list
}

variable "public_subnet_cidr"{
  description = "Provide the cidr of the Public Subnet of VPC"
  type = list
}

variable "igw_name" {
  description = "Provide the Name of Internet Gateway for VPC"
  type = string
}

variable "vpc_name" {
  description = "Provide the Name of VPC"
  type = string
}

data "aws_availability_zones" "azs" {

}

########################################### Variables for ALB and ASG #################################################
variable "prefix" {
  description = "Provide the path in bucket whereAccess logs will be captured"
  type = string
}
variable "alb_tg_name" {
  description = "Provide the Target Group Name"
  type = string
}
variable "sg_name" {
  description = "Provide the security group name"
  type = string
}
variable "sg_description" {
  description = "Description for Security group for ALB"
  type = string
}
variable "cidr_blocks" {
  description = "Provide CIDR Block for Security Group"
  type = list
}
variable "s3_bucket_exists" {
  description = "Create S3 bucket only if doesnot exists."
  type = bool
}
variable "access_log_bucket" {
  description = "S3 bucket to capture Application LoadBalancer"
  type = string
}
variable "alb_name" {
  description = "Provide the ALB Name"
  type = string
}
variable "internal_external" {
  description = "Provide the option for LoadBalancer to be internal or external"
  default = false
}
variable "instance_port" {
  description = "Provide the Instance Port for Target Group"
  type = number
}
variable "instance_protocol" {
  description = "Provide the protocol for the Target Group"
  type = string
}
variable "loadbalancer_type" {
  description = "Provide the LoadBalancer Type"
  type = list
}
variable "enable_deletion_protection" {
  description = "To enable or disable the deletion protection"
  type = bool
}
variable "target_type" {
  description = "Select the target type from the list"
  type = list
}
variable "healthy_threshold" {
  description = "Provide the healthy threshold"
  type = number
}
variable "interval" {
  description = "Provide the interval for health check of loadbalancer"
  type = number
}
variable "unhealthy_threshold" {
  description = "Provide the unhealthy threshold"
  type = number
}
variable "timeout" {
  description = "Provide the timeout time in seconds"
  type = number
}
variable "healthcheck_path" {
  description = "Provide the health check path"
  type = string
}
variable "healthcheck_protocol" {
  description = "Provide the healthcheck protocol"
  type = string
}
variable "ssl_policy" {
  description = "Provide the SSL Policy for SSL Certificate"
  type = list
}
#variable "certificate_arn" {
#  description = "Provide the AWS certificate ARN"
#  type = string
#}
variable "kms_key_id" {
  description = "Provide the KMS Key ID to encrypt EBS"
  type = string
}
#variable "launchconfiguration_name" {
#  description = "Provide the Launchconfiguration Name"
#  type = string
#  default = "MyLC"
#}
variable "launch_template_name" {
  description = "Provide the Launch Template Name"
  type = string
}
#variable "image_id" {
#  description = "Provide the Image ID"
#  type = string
#  default = 
#}
variable "instance_type" {
  description = "Provide the Instance Type"
  type = list
}
variable "iam_instance_profile" {
  description = "Provide the IAM Role Name to be associated with the AMI"
  type = string
}
variable "key_name" {
  description = "Provide the Key-Pair Name"
  type = list
}
variable "associate_public_ip_address" {
  description = "Select public ip address to be associated with an instance"
  type = bool
}
variable "enable_monitoring" {
  description = "To enable or disable the monitoring"
  type = bool
}
variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type = list
}
variable "placement_tenancy" {
  description = "The tenancy of the instance. Select default or dedicated"
  type = list
}
variable "asg_name" {
  description = "Provide the Autoscaling Group Name"
  type = string
}
variable "min_size" {
  description = "Provide the minimum size for Autoscale Cluster"
  type = number
}
variable "max_size" {
  description = "Provide the maximum size for Autoscale Cluster"
  type = number
}
variable "desired_capacity" {
  description = "Provide the Desired capacity of Autoscaling Group"
  type = number
}
variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start"
  type = number
}
variable "service_linked_role_arn" {
  description = "Provide the Service Linked Role ARN for Autoscaling"
  type = string
}
variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type = number
}
variable "health_check_type" {
  description = "Select the health check type as EC2 or ELB"
  type = list
}
variable "force_delete" {
  description = "Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate"
  type = bool
}
variable "treat_missing_data" {
  description = "Sets how this alarm is to handle missing data points"
  type = list
}
variable "sns_topic_name" {
  description = "Provide the AWS SNS Topic Name"
  type = string
}
variable "env" {
  description = "Provide the Environment for the resources"
  type = list
}

####################################################### Variables to create Route 53 Hosted Zone #######################################################

variable "name" {
  description = "Provide the name of the Route53 Hosted Zone"
  type = string
}

######################################################## Variables for Jenkins #########################################################################

variable "provide_ami" {
  description = "Provide the AMI ID for the EC2 Instance"
  type = map
}
