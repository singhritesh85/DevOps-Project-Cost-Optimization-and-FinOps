# Security Group for ALB
resource "aws_security_group" "allow_tls" {
  name        = var.sg_name
  description = var.sg_description
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
    Name = "test-sg"
  }
}

#S3 Bucket to capture ALB access logs
resource "aws_s3_bucket" "bucket" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = var.access_log_bucket
  
  force_destroy = true

  tags = {
    Environment = var.env
  }
}

#S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

data "aws_caller_identity" "G_Duty" {
}

#Apply Bucket Policy to S3 Bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
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
          "Resource": [
            "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*",
            "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder_jenkins/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
          ]
        }  
      ]
    }
  EOF

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.bucket_encryption]
}

# Application LoadBalancer
resource "aws_lb" "application-loadbalancer" {
  name               = var.alb_name
  internal           = var.internal_external
  load_balancer_type = var.loadbalancer_type
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = aws_subnet.public_subnet[*].id
  idle_timeout       = 60
  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.access_log_bucket
    prefix  = var.prefix
    enabled = true
  }

  tags = {
    Environment = var.env
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "autoscale_alb_tg" {
  name        = var.alb_tg_name
  target_type = var.target_type
  port        = var.instance_port 
  protocol    = var.instance_protocol
  vpc_id      = aws_vpc.test_vpc.id
  health_check {
    enabled = true
    healthy_threshold = var.healthy_threshold
    interval = var.interval
    path = var.healthcheck_path
    port = "traffic-port"
    protocol = var.healthcheck_protocol
    timeout = var.timeout
    unhealthy_threshold = var.unhealthy_threshold 
  }
  depends_on = [ aws_lb.application-loadbalancer ]

  tags = {
    Environment = var.env
  }
}

# HTTP Listener for ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application-loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.autoscale_alb_tg.arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

# HTTPS Listener for ALB
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.application-loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.acm_cert.arn   ###var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.autoscale_alb_tg.arn
  }

}

# Launch Configuration for ASG
#resource "aws_launch_configuration" "asg_lc" {
#  name   = var.launchconfiguration_name
#  image_id      = var.AMI_ID
#  instance_type = var.instance_type
#  iam_instance_profile = var.iam_instance_profile
#  key_name = var.key_name
#  security_groups = var.security_groups
#  associate_public_ip_address = var.associate_public_ip_address
#  enable_monitoring = var.enable_monitoring
#  ebs_optimized = var.ebs_optimized
#  root_block_device {
#    volume_type = "gp2"
#    volume_size = 10
#    delete_on_termination = true
#    encrypted = true
#  }
#  user_data = <<-EOF
#              #!/bin/bash
#              yum update -y
#              yum install -y httpd
#              service httpd start
#              chkconfig httpd on
#              echo "<h1>Deployed Via Terraform</h1>" >> /var/www/html/index.html
#              EOF
  
#  placement_tenancy = var.placement_tenancy

#  lifecycle {
#    create_before_destroy = true
#  }
#}

# Security Group for Jenkins-Master
resource "aws_security_group" "asg_spot_instances" {
  name        = "ASG-Spot-Instances"
  description = "Security Group for ASG Spot Instances"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.allow_tls.id]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.allow_tls.id]
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

# Launch Template for ASG
resource "aws_launch_template" "launch_template_asg" {
  image_id               = var.AMI_ID         
  instance_type          = var.instance_type[0]
  name                   = var.launch_template_name
  key_name               = var.key_name
  ebs_optimized = var.ebs_optimized
#  update_default_version = true

  instance_market_options {
    market_type = "spot"

    spot_options {
#     max_price                      = "0.01"  ### If omitted, AWS uses the current Spot price up to the On-Demand price.
      spot_instance_type             = "one-time"  ### AWS tries to Launch once. If interrupted, the request ends.
      instance_interruption_behavior = "terminate"   ### Instance terminates when interrupted.
    }
  }

  monitoring {
    enabled = var.enable_monitoring
  }
  
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = [aws_security_group.asg_spot_instances.id]
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  placement {
    tenancy = var.placement_tenancy
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 10
      volume_type = "gp3"
      encrypted = true
      kms_key_id = var.kms_key_id     ### Provide the kms_key_id for your AWS Account.
      delete_on_termination = true
    }
  }
 
  tag_specifications {
    resource_type = "instance"
    tags = {
      Environment = var.env       
    }
  }
  
  tag_specifications {
     resource_type = "volume"
     tags = {
       Environment = var.env    
    }
  } 

  user_data = filebase64("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.application-loadbalancer, aws_lb_target_group.autoscale_alb_tg]
}

# AutoScaling Group
resource "aws_autoscaling_group" "asg" {
  name                 = var.asg_name
#  launch_configuration = aws_launch_configuration.asg_lc.name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity  
  vpc_zone_identifier  = aws_subnet.private_subnet[*].id   ###aws_subnet.public_subnet[*].id
  default_cooldown     = var.default_cooldown  # The amount of time, in seconds, after a scaling activity completes before another scaling activity can start.
  service_linked_role_arn = var.service_linked_role_arn
  health_check_grace_period = var.health_check_grace_period   # Time (in seconds) after instance comes into service before checking health.
  health_check_type    = var.health_check_type
  force_delete         = var.force_delete # Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate.
  target_group_arns    = [aws_lb_target_group.autoscale_alb_tg.arn]
  termination_policies = ["OldestLaunchTemplate"]               ### ["OldestLaunchConfiguration"]
  
  launch_template {
    id      = aws_launch_template.launch_template_asg.id
    version = "$Latest"
  }

  tag {
          key                 = "Environment"
          value               = var.env
          propagate_at_launch = true
  }
  

  lifecycle {
    create_before_destroy = true
  }
 
  depends_on = [ aws_launch_template.launch_template_asg ]    ### [ aws_launch_configuration.asg_lc ]
}

# AutoScaling Policy for Scale UP
resource "aws_autoscaling_policy" "scaleup" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "scaleout"
  policy_type            = "StepScaling"
#  cooldown               = 100  # The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start, used for SimpleScaling.
  adjustment_type        = "ChangeInCapacity" 
  estimated_instance_warmup = 100  # The estimated time, in seconds, until a newly launched instance will contribute CloudWatch metrics. 

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = ""   # Without a value, AWS will treat this bound as infinity.
  }
  
  depends_on = [aws_launch_template.launch_template_asg, aws_autoscaling_group.asg]    ###[ aws_launch_configuration.asg_lc, aws_autoscaling_group.asg ]

}

# AutoScaling Policy for Scale Down
resource "aws_autoscaling_policy" "scaledown" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "scalein"
  policy_type            = "StepScaling"
#  cooldown               = 100  # The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start, used for SimpleScaling.
  adjustment_type        = "ChangeInCapacity"
  estimated_instance_warmup = 100  # The estimated time, in seconds, until a newly launched instance will contribute CloudWatch metrics.

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_lower_bound = "" # Without a value, AWS will treat this bound as infinity.
    metric_interval_upper_bound = 0  # Without a value, AWS will treat this bound as infinity.
  }
  
  depends_on = [aws_launch_template.launch_template_asg, aws_autoscaling_group.asg]    ###[ aws_launch_configuration.asg_lc, aws_autoscaling_group.asg ]

}

data "aws_sns_topic" "cloudwatch_alerts" {
  name = var.sns_topic_name
}

# Cloudwatch Alarms
resource "aws_cloudwatch_metric_alarm" "cloudwatchalarm_high" {
  alarm_name          = "CloudwatchAlarm-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors autoscaling ec2 scaleup cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scaleup.arn, data.aws_sns_topic.cloudwatch_alerts.arn]
  depends_on = [ aws_autoscaling_policy.scaleup ]

  tags = {
    Environment = var.env
  }
}


resource "aws_cloudwatch_metric_alarm" "cloudwatchalarm_low" {
  alarm_name          = "CloudwatchAlarm-Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors autoscaling ec2 scaledown cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scaledown.arn, data.aws_sns_topic.cloudwatch_alerts.arn]
  depends_on = [ aws_autoscaling_policy.scaledown ]

  tags = {
    Environment = var.env
  }
}

#################################### CloudWatch Alarm to Monitor Spot Instances Interruption and Termination #########################################

resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "capture-spot-interruption"
  description = "Triggers when AWS issues a 2-minute Spot Instance termination notice"

  event_pattern = jsonencode(
    {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    }
  )
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "SendToSNS"
  arn       = data.aws_sns_topic.cloudwatch_alerts.arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  # Default SNS topic owner permissions
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    resources = [
      data.aws_sns_topic.cloudwatch_alerts.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.G_Duty.account_id
      ]
    }
  }

  # Allow EventBridge to publish Spot interruption events
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions = [
      "SNS:Publish"
    ]
    resources = [
      data.aws_sns_topic.cloudwatch_alerts.arn
    ]
  }
}

resource "aws_sns_topic_policy" "attach_policy_to_topic" {
  arn    = data.aws_sns_topic.cloudwatch_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# EventBridge Rule for EC2 Terminated State
resource "aws_cloudwatch_event_rule" "ec2_terminated" {
  name        = "ec2-spot-terminated-rule"
  description = "Alert when a Spot Instance enters terminated state"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["terminated"]
    }
  })
}

# Route to SNS Topic
resource "aws_cloudwatch_event_target" "sns_terminated_target" {
  rule      = aws_cloudwatch_event_rule.ec2_terminated.name
  target_id = "SendTerminatedToSNS"
  arn       = data.aws_sns_topic.cloudwatch_alerts.arn
}
