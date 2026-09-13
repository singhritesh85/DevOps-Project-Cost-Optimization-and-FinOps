output "hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone."
  value       = aws_route53_zone.hosted_zone.zone_id
}

output "hosted_zone_name_servers" {
  description = "The name servers for the Route 53 Hosted Zone."
  value       = aws_route53_zone.hosted_zone.name_servers
}

output "certificate_arn" {
  description = "The AWS ACM Certificate ARN"
  value = aws_acm_certificate.acm_cert.arn
}

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = aws_lb.application-loadbalancer.dns_name
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.desired_capacity
}

output "efs_mount_target_ips" {
  value       = aws_efs_mount_target.efs_mount_target.ip_address
  description = "The private IP addresses of the EFS mount targets."
}

output "jenkins_alb_dns_name" {
  description = "DNS Name of Jenkins ALB"
  value = aws_lb.test-application-loadbalancer.dns_name
}
