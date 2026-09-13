############################### Create VPC #######################################

resource "aws_vpc" "test_vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-${var.env}"                     ##"test-vpc"
    Environment = var.env            ##"${terraform.workspace}"
  }
}

############################### Public Subnet for VPC ##########################################

resource "aws_subnet" "public_subnet" {
  count = "${length(data.aws_availability_zones.azs.names)}"
  vpc_id     = "${aws_vpc.test_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  cidr_block = "${element(var.public_subnet_cidr,count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${var.env}-${count.index+1}"
    Environment = var.env            ##"${terraform.workspace}"
  }
}

############################### Private Subnet for VPC #########################################

resource "aws_subnet" "private_subnet" {
  count = "${length(data.aws_availability_zones.azs.names)}"                  ##"${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"
  vpc_id     = "${aws_vpc.test_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  cidr_block = "${element(var.private_subnet_cidr,count.index)}"

  tags = {
    Name = "PrivateSubnet-${var.env}-${count.index+1}"
    Environment = var.env                ##"${terraform.workspace}"
  }
}

############################### Public Route Table for VPC ####################################

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

############################### Default Route Table for VPC ###################################

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.test_vpc.default_route_table_id

   tags = {
    Name = "default-route-table-${var.env}"
    Environment = var.env               ##"${terraform.workspace}"
  }

}

############################### Private Route Table for VPC ###################################

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "Private-route-table-${var.env}"
   Environment = var.env                  ##"${terraform.workspace}"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count = "${length(data.aws_availability_zones.azs.names)}"                        ##"${length(slice(data.aws_availability_zones.azs.names, 0, 2))}"
  subnet_id      = aws_subnet.private_subnet[count.index].id                                   ##aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.private_route_table.id
}

############################################# Internet Gateway for VPC ####################################################

resource "aws_internet_gateway" "testIGW" {
  
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "${var.igw_name}-${var.env}"        #"test-IGW"
    Environment = var.env               ##"${terraform.workspace}"
  }
}

############################ Security Group for VPC to Allow Traffic for RDS ###############################

resource "aws_security_group" "rds_traffic" {
 name        = "RDS-Security-Group-${var.env}"
 description = "Allow RDS Traffic"
 vpc_id      = aws_vpc.test_vpc.id

ingress {
   description = "Allow All Traffic"
   from_port   = 3306
   to_port     = 3306
   protocol    = "tcp"
   cidr_blocks = [var.vpc_cidr]    ### Allow all traffic for AWS VPC CIDR
 }

ingress {
   description = "Allow All Traffic"
   from_port   = 5432
   to_port     = 5432
   protocol    = "tcp"
   cidr_blocks = [var.vpc_cidr]    ### Allow all traffic for AWS VPC CIDR
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}


