################################################AWS VPC#################################################################################

resource "aws_vpc" "test_vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true    ### By default it is true.

  tags = {
    Name = "${var.vpc_name}-${var.env}"                     ##"test-vpc"
    Environment = var.env            ##"${terraform.workspace}"
  }
}

############################### Public Subnet ##########################################

resource "aws_subnet" "public_subnet" {
  count = "${length(data.aws_availability_zones.azs.names)}"
  vpc_id     = "${aws_vpc.test_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  cidr_block = "${element(var.public_subnet_cidr,count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${var.env}-${count.index+1}"
    Environment = var.env            ##"${terraform.workspace}"
    "karpenter.sh/discovery" = "${var.eks_cluster}-${var.env}"
    "kubernetes.io/role/elb" = "1"
  }
}

############################### Private Subnet #########################################

resource "aws_subnet" "private_subnet" {
  count = "${length(data.aws_availability_zones.azs.names)}"                  ##"${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"
  vpc_id     = "${aws_vpc.test_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  cidr_block = "${element(var.private_subnet_cidr,count.index)}"

  tags = {
    Name = "PrivateSubnet-${var.env}-${count.index+1}"
    Environment = var.env                ##"${terraform.workspace}"
    "karpenter.sh/discovery" = "${var.eks_cluster}-${var.env}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

############################### Public Route Table ####################################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testIGW.id
  }

  tags = {
    Name = "public-route-table-${var.env}"
    Environment = var.env              ##"${terraform.workspace}"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

############################### Private Route Table ###################################

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.test_vpc.default_route_table_id

   tags = {
    Name = "default-route-table-${var.env}"
    Environment = var.env               ##"${terraform.workspace}"
  }

}

resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
}

  tags = {
    Name = "Private-route-table-1-${var.env}"
   Environment = var.env                  ##"${terraform.workspace}"
  }
}

resource "aws_route_table_association" "private_route_table_association_1" {
#  count = "${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"           ##"${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = aws_subnet.private_subnet[0].id                                   ##aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
}

  tags = {
    Name = "Private-route-table-2-${var.env}"
   Environment = var.env                  ##"${terraform.workspace}"
  }
}

resource "aws_route_table_association" "private_route_table_association_2" {
#  count = "${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"        ## "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = aws_subnet.private_subnet[1].id                             ## aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table_2.id
}

resource "aws_route_table" "private_route_table_3" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
}

  tags = {
    Name = "Private-route-table-3-${var.env}"
   Environment = var.env                  ##"${terraform.workspace}"
  }
}

resource "aws_route_table_association" "private_route_table_association_3" {
#  count = "${length(data.aws_availability_zones.azs.names)}"       ##"${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"
  subnet_id      = aws_subnet.private_subnet[2].id         ## aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table_3.id
}

############################################## NAT Gateway #######################################################

resource "aws_eip" "nat" {
  domain   = "vpc"
  # vpc      = true
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on    = [aws_internet_gateway.testIGW]

  tags = {
    Name = "${var.natgateway_name}-${var.env}"            ##"NAT_Gateway"
    Environment = var.env          ##"${terraform.workspace}"
  }
}

############################################# Internet Gateway ####################################################

resource "aws_internet_gateway" "testIGW" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "${var.igw_name}-${var.env}"        #"test-IGW"
    Environment = var.env               ##"${terraform.workspace}"
  }
}

############################################ Security Group to Allow All Traffic ##################################

resource "aws_security_group" "all_traffic" {
 name        = "AllTraffic-Security-Group-${var.env}"
 description = "Allow All Traffic"
 vpc_id      = aws_vpc.test_vpc.id

ingress {
   description = "Allow All Traffic"
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

############################################## Cpture VPC Flow Logs in S3 Bucket ##################################

resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket        = "${var.prefix}-vpc-flow-logs-2026"
  force_destroy = true

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

###S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_flow_logs_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

###Enforce Strict Private Access
resource "aws_s3_bucket_public_access_block" "flow_logs_bucket_privacy" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    id     = "vpc-flow-logs-retention-policy"
    status = "Enabled"

    # Move to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier Flexible Retrieval after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Permanently discard logs after 365 days
    expiration {
      days = 365
    }
  }
}

### Enable VPC Flow Logs pointing to the S3 Bucket
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.test_vpc.id

  destination_options {
    file_format                = "plain-text"    ###"parquet"
    hive_compatible_partitions = false
    per_hour_partition         = false    ###Will be used in case of Athena to reduce the cost.
  }
}
