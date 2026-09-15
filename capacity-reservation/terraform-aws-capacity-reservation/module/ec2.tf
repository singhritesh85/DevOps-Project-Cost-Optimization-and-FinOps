############################################################### Dexter-Server #####################################################################

resource "aws_security_group" "dexter_server" {
  name        = "Dexter-Server-SG"
  description = "Security Group for Dexter Server Node"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dexter-server-sg"
  }
}

############################################################# Dexter-Server ###########################################################################

resource "aws_instance" "dexter_server" {
  count         = 2
  ami           = var.provide_ami
  instance_type = var.instance_type
  monitoring = true
  vpc_security_group_ids = [aws_security_group.dexter_server.id]  ### var.vpc_security_group_ids       ###[aws_security_group.all_traffic.id]
  subnet_id = aws_subnet.public_subnet[0].id                                 ###aws_subnet.public_subnet[0].id
  root_block_device{
    volume_type="gp2"
    volume_size="20"
    encrypted=true
    kms_key_id = var.kms_key_id
    delete_on_termination=true
  }
  user_data = file("user_data_dexter.sh")
  iam_instance_profile = "Administrator_Access"  # IAM Role to be attached to EC2

  lifecycle{
    prevent_destroy=false
    ignore_changes=[ ami ]
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  metadata_options { #Enabling IMDSv2
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  capacity_reservation_specification {
    capacity_reservation_preference = count.index == 0 ? "open" : null

    dynamic "capacity_reservation_target" {
      for_each = count.index == 0 ? [] : [1]
      content {
        capacity_reservation_id = aws_ec2_capacity_reservation.capacity_reservation[1].id
      }
    }
  }

  tags={
    Name="${var.prefix}-${var.name}-Server-${count.index + 1}"
    Environment = var.env
    EBS-backed-AMI = "true"
  }
}
resource "aws_eip" "eip_associate" {
  count  = 2
  domain = "vpc"     ###vpc = true
}
resource "aws_eip_association" "eip_association" {  ### I will use this EC2 behind the ALB.
  count         = 2
  instance_id   = aws_instance.dexter_server[count.index].id
  allocation_id = aws_eip.eip_associate[count.index].id
}
