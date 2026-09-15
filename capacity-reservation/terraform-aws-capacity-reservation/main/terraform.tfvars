##################################################### Provide Parameters for AWS VPC ###############################################

region = "us-east-2"
prefix = "AWS"

vpc_cidr            = "192.168.0.0/16"
private_subnet_cidr = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
public_subnet_cidr  = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
igw_name            = "test-IGW"
natgateway_name     = "EKS-NatGateway"
vpc_name            = "test-vpc"
env                 = ["dev", "stage", "prod"]

######################################################Parameters to launch EC2####################################################

instance_count = 1
instance_type  = ["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"]
provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-028ba4d4ccb4b7b72" ###"ami-0169aa51f6faf20d5"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
#subnet_id = "subnet-XXXXXXXXXXXXXXXXX"
#vpc_security_group_ids = ["sg-00cXXXXXXXXXXXXX9"]
cidr_blocks = ["0.0.0.0/0"]
name        = "Dexter"

kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ### Provide the ARN of KMS Key.
