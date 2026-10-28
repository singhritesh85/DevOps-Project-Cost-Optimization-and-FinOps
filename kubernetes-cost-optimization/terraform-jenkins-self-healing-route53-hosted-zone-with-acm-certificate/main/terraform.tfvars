################################## Parameters to create the infrastructure ######################################

region = "us-east-2"
cidr_blocks = ["0.0.0.0/0"]
s3_bucket_exists = false
access_log_bucket = "s3bucketcapturealblog"
env = ["dev", "stage", "prod"]
vpc_name = "test-vpc-dev"
#public_subnets = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"] 
#private_subnets = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"]
#vpc_id = "vpc-XXXXXXXXXXXXXXXXX"
ssl_policy = ["ELBSecurityPolicy-2016-08", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01", "ELBSecurityPolicy-TLS-1-2-Ext-2018-06", "ELBSecurityPolicy-FS-2018-06", "ELBSecurityPolicy-2015-05"]
service_linked_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
certificate_arn = "arn:aws:acm:us-east-2:02XXXXXXXXX6:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-052b3645c2c811821"     ###"ami-0c6ac5f2fed2981b0"        ###"ami-09256c524fab91d36"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
instance_type = [ "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge" ]
name = "singhritesh85.com"
