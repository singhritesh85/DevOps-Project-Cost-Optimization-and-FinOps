output "gcp_instance_template_vm_instance_autoscale_alb_mysql_gitlab_vm_instance_private_static_ip_gcp_alb_static_ip_and_gcp_cloud_dns_details" {
  description = "Details of the Google Cloud Instance Template, Instance Group, VM Instance, Autoscale, Application LoadBalancer, MySQL and GCP Cloud DNS"
  value       = "${module.autoscale_alb}"
}
