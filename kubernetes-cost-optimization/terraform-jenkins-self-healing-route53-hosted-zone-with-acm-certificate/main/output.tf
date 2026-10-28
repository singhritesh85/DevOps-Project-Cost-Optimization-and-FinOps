output "efs_private_ip_dns_name_of_jenkins_alb" {
  description = "EFS_Private_IP and DNS Name of Jenkins ALB"
  value       = "${module.jenkins_self_healing}"
}
