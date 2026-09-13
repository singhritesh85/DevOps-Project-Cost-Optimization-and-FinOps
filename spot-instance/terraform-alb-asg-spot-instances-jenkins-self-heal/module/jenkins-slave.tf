###################################################### Jenkins-Slave Security Group ###################################################################

resource "aws_security_group" "jenkins_slave" {
  name        = "Jenkins-Slave"
  description = "Security Group for Jenkins Slave Node"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
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
    Name = "k8s-managemnt-sg"
  }
}

########################################## Jenkins-Slave Launch Template and AutoScaling Group ######################################################

resource "aws_launch_template" "jenkins_slave" {
  name_prefix = "jenkins-worker-"
  image_id = var.provide_ami
  instance_type = var.instance_type[2]
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    name = "Administrator_Access"
  }
  vpc_security_group_ids = [aws_security_group.jenkins_slave.id]
  user_data = filebase64("user_data_jenkins_slave.sh")
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
    }
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      kms_key_id            = var.kms_key_id
      delete_on_termination = true
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type = "ip-name"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name            = "Jenkins-Slave"
      Environment     = var.env
      EBS-backed-AMI  = "true"
      Role            = "jenkins-worker"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "jenkins-slave-root-volume"
      Environment = var.env
      Role        = "jenkins-worker"
    }
  }
}

resource "aws_autoscaling_group" "jenkins_slave" {
  name = "jenkins-worker-asg"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  vpc_zone_identifier = aws_subnet.public_subnet[*].id
  capacity_rebalance = true
  health_check_type = "EC2"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.jenkins_slave.id
    version = aws_launch_template.jenkins_slave.latest_version
  }
  tag {
    key                 = "Name"
    value               = "Jenkins-Slave-${timestamp()}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "jenkins-worker"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
