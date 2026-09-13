output "efs_private_ip_alb_dns_name_route53_hosted_zone_acm_certificate_asg_details" {
  description = "EFS_Private IP, ALB DNS Name, AutoScaling Group, Route53 Hosted Zone ID, Nameserver, ACM Certificate ARN"
  value       = "${module.autoscale_packer}"
}
