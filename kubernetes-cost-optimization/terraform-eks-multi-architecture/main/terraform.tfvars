##################################################### Provide Parameters for AWS VPC ###############################################

region = "us-east-2"
prefix = "multiarchitecture"

vpc_cidr            = "192.168.0.0/16"
private_subnet_cidr = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
public_subnet_cidr  = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
igw_name            = "test-IGW"
natgateway_name     = "EKS-NatGateway"
vpc_name            = "test-vpc"
env                 = ["dev", "stage", "prod"]

##################################################### Parameters for EKS ###########################################################

eks_cluster            = "eks-demo-cluster"
eks_iam_role_name      = "eks-iam-role"
node_group_name        = "eks-nodegroup"
eks_nodegrouprole_name = "eks-nodegroup-role"
launch_template_name   = "eks-launch-template"
#eks_ami_id = ["ami-0f5a11c59a157c25a", "ami-076fda1d45f0f46d7"]
instance_type                   = ["t3.micro", "t3.small", "t3.medium", "t3a.micro", "t3a.small", "t3a.medium", "t4g.micro", "t4g.small", "t4g.medium"]
disk_size                       = "30"
ami_type                        = ["AL2023_x86_64_STANDARD", "AL2_x86_64", "AL2023_ARM_64_STANDARD", "CUSTOM"]
release_version                 = ["1.23.16-20230217", "1.24.10-20230217", "1.25.6-20230217", "1.26.12-20240110", "1.27.9-20240110", "1.28.5-20240110", "1.29.8-20241109", "1.30.4-20241109", "1.31.11-20250804", "1.32.7-20250804", "1.33.0-20250519", "1.34.8-20260527", "1.35.5-20260527", "1.36.4-20260917"]
kubernetes_version              = ["1.23", "1.24", "1.25", "1.26", "1.27", "1.28", "1.29", "1.30", "1.31", "1.32", "1.33", "1.34", "1.35", "1.36"]
capacity_type                   = ["ON_DEMAND", "SPOT"]
ebs_csi_name                    = "aws-ebs-csi-driver"
ebs_csi_version                 = ["v1.61.1-eksbuild.1", "v1.39.0-eksbuild.1", "v1.28.0-eksbuild.1", "v1.27.0-eksbuild.1", "v1.26.1-eksbuild.1", "v1.25.0-eksbuild.1"] #####"v1.21.0-eksbuild.1"
node_monitoring_version         = ["v1.7.1-eksbuild.1", "v1.7.0-eksbuild.1", "v1.6.6-eksbuild.1"]
addon_version_guardduty         = ["v1.15.0-eksbuild.2", "v1.12.1-eksbuild.2", "v1.10.0-eksbuild.2", "v1.9.0-eksbuild.2", "v1.8.1-eksbuild.2", "v1.4.1-eksbuild.2", "v1.4.0-eksbuild.1", "v1.3.1-eksbuild.1", "v1.2.0-eksbuild.3"]
addon_version_kubeproxy         = ["v1.36.0-eksbuild.17", "v1.35.3-eksbuild.11", "v1.33.7-eksbuild.2", "v1.32.6-eksbuild.6", "v1.31.10-eksbuild.6", "v1.30.9-eksbuild.3", "v1.28.15-eksbuild.9", "v1.27.10-eksbuild.2", "v1.27.8-eksbuild.4", "v1.27.8-eksbuild.1", "v1.27.6-eksbuild.2"]
addon_version_vpc_cni           = ["v1.22.1-eksbuild.2", "v1.19.2-eksbuild.5", "v1.19.2-eksbuild.5", "v1.16.3-eksbuild.2", "v1.16.0-eksbuild.1", "v1.15.5-eksbuild.1", "v1.15.1-eksbuild.1"]
addon_version_coredns           = ["v1.14.3-eksbuild.2", "v1.11.4-eksbuild.2", "v1.10.1-eksbuild.18", "v1.10.1-eksbuild.7", "v1.10.1-eksbuild.6", "v1.10.1-eksbuild.5", "v1.10.1-eksbuild.4"]
csi_snapshot_controller_version = ["v8.6.0-eksbuild.2", "v8.4.0-eksbuild.3", "v8.2.0-eksbuild.1", "v8.1.0-eksbuild.2", "v8.1.0-eksbuild.1", "v7.0.1-eksbuild.1", "v6.3.2-eksbuild.1"]
addon_version_observability     = ["v6.2.0-eksbuild.1", "v5.1.0-eksbuild.1", "v4.1.0-eksbuild.1", "v4.0.0-eksbuild.1", "v3.7.0-eksbuild.1", "v3.5.0-eksbuild.1"]
addon_version_podidentityagent  = ["v1.3.10-eksbuild.3", "v1.3.7-eksbuild.2", "v1.3.5-eksbuild.2", "v1.3.4-eksbuild.1", "v1.3.0-eksbuild.1", "v1.2.0-eksbuild.1"]
addon_version_metrics_server    = ["v0.8.1-eksbuild.10", "v0.7.2-eksbuild.3", "v0.7.2-eksbuild.2", "v0.7.2-eksbuild.1"]

######################################################Parameters to launch EC2####################################################

instance_count = 1
provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-08be4b1b8afa29958" ###"ami-0169aa51f6faf20d5"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
#subnet_id = "subnet-XXXXXXXXXXXXXXXXX"
#vpc_security_group_ids = ["sg-00cXXXXXXXXXXXXX9"]
cidr_blocks = ["0.0.0.0/0"]
name        = "K8S-Management"

kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ### Provide the ARN of KMS Key to encrypt EBS.

###################################################Parameters to Encrypt EKS Backup###############################################

backup_kms_key_arn = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ### Provide the ARN of KMS Key to encrypt EKS Backup.
