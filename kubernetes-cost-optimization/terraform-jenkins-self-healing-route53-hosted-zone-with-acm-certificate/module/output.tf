output "efs_mount_target_ips" {
  value       = aws_efs_mount_target.efs_mount_target.ip_address
  description = "The private IP addresses of the EFS mount targets."
}

output "jenkins_alb_dns_name" {
  description = "DNS Name of Jenkins ALB"
  value = aws_lb.test-application-loadbalancer.dns_name
}
