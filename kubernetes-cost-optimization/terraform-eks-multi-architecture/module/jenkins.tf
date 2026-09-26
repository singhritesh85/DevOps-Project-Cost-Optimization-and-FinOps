# Security Group for ALB
resource "aws_security_group" "security_group_alb" {
  name        = "Security-Group-ALB"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = var.cidr_blocks
    from_port  = 80
    to_port    = 80
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security-Group-ALB"
  }
}

#S3 Bucket to capture ALB access logs
resource "aws_s3_bucket" "s3_bucket" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = var.access_log_bucket

  force_destroy = true

  tags = {
    Environment = var.env
  }
}

#S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3bucket_encryption" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

#data "aws_caller_identity" "G_Duty" {
#}

#Apply Bucket Policy to S3 Bucket
resource "aws_s3_bucket_policy" "s3bucket_policy_jenkins" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  policy = <<EOF
    {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": "arn:aws:iam::033677994240:root"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder_jenkins/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
         }
       ]
    }
  EOF

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.s3bucket_encryption]
}

resource "aws_lb" "test-application-loadbalancer" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group_alb.id]
  subnets            = aws_subnet.public_subnet[*].id      ###var.public_subnets

  enable_deletion_protection = false
  idle_timeout = 60
  access_logs {
    bucket  = var.access_log_bucket
    prefix  = "application_loadbalancer_log_folder_jenkins"
    enabled = true
  }

  tags = {
    Environment = "Dev"
  }
}

#Target Group of Application Loadbalancer
resource "aws_lb_target_group" "target_group" {
  name     = "jenkins-TG"
  port     = "8080"  ##### Don't use protocol when target type is lambda
  protocol = "HTTP"  ##### Don't use protocol when target type is lambda
  vpc_id   = aws_vpc.test_vpc.id
  target_type = "instance"
  load_balancing_algorithm_type = "round_robin"
  health_check {
    enabled = true ## Indicates whether health checks are enabled. Defaults to true.
    path = "/login"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 40
  }
}

##Application Loadbalancer listener for HTTP
resource "aws_lb_listener" "alb_listener_front_end_HTTP" {
  load_balancer_arn = aws_lb.test-application-loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.target_group.arn
     redirect {    ### Redirect HTTP to HTTPS
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

##Application Loadbalancer listener for HTTPS
resource "aws_lb_listener" "alb_listener_front_end_HTTPS" {
  load_balancer_arn = aws_lb.test-application-loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Security Group for Jenkins-Master
resource "aws_security_group" "jenkins_master" {
  name        = "Jenkins-master"
  description = "Security Group for Jenkins Master ALB"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups  = [aws_security_group.security_group_alb.id]
  }

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
    Name = "jenkins-master-sg"
  }
}

resource "aws_launch_template" "demo_launch_template" {
  name          = "jenkins-launch-template"
  image_id      = var.provide_ami
  instance_type = var.instance_type[5]
#  iam_instance_profile = "Administrator_Access"   ### IAM Role to be attached to EC2
  ebs_optimized = true
#  key_name = var.key_name
#  vpc_security_group_ids = [aws_security_group.jenkins_master.id]
  user_data = base64encode(templatefile("jenkins_master.sh", {jenkins_efs_ip_address = aws_efs_mount_target.efs_mount_target.ip_address}))
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      encrypted = true
      kms_key_id = var.kms_key_id     ### Provide the kms_key_id for your AWS Account.
    }
  }
  placement {
    tenancy = "default"
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.jenkins_master.id]
  }
  monitoring {
    enabled = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo_autoscaling_group" {
  name     = "jenkins-autosacling-group"
  min_size = 1
  max_size = 1
  desired_capacity = 1
  vpc_zone_identifier = [aws_subnet.public_subnet[0].id]        ###[var.public_subnets[0]]
  default_cooldown = 10                                     ##Time between a scaling activity and the succeeding scaling activity.
  service_linked_role_arn = var.service_linked_role_arn
  health_check_grace_period = 600
  health_check_type = "ELB"
  force_delete = true 
  target_group_arns = [aws_lb_target_group.target_group.arn]
  termination_policies = ["OldestInstance"]
  launch_template {
    id      = aws_launch_template.demo_launch_template.id
    version = aws_launch_template.demo_launch_template.latest_version
  }
  tag {
    key = "Environment" 
    value = "Dev"
    propagate_at_launch = true  ### Tags automatically inherited by EC2 Instances.
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_efs_mount_target.efs_mount_target]
}

resource "aws_security_group" "efs_ingress" {
  name   = "efs-ingress-jenkins"
  vpc_id = aws_vpc.test_vpc.id

  ingress {

    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "jenkins_EFS" {
  creation_token   = "Jenkins-EFS"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Name = "Elastic-File-System-Jenkins"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id  = aws_efs_file_system.jenkins_EFS.id
  subnet_id       = aws_subnet.public_subnet[0].id         ###var.public_subnets[0]
  security_groups = [aws_security_group.efs_ingress.id]
}

