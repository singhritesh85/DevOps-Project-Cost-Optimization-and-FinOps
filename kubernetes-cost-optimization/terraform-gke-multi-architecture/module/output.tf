output "cloud_dns_zone_id" {
  description = "The ID of the GCP Cloud DNS Zone."
  value       = google_dns_managed_zone.dexter_public_zone.id
}

output "gcp_cloud_dns_zone_name_servers" {
  description = "The name servers for the GCP Cloud DNS Zone."
  value       = google_dns_managed_zone.dexter_public_zone.name_servers
}

output "gcp_vm_private_ip_address" {
  value = google_compute_instance.vm_instance[*].network_interface[0].network_ip
  description = "The primary internal IP address of the VM Instances"
}

output "gcp_vm_public_ip_address" {
  value       = google_compute_instance.vm_instance[*].network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the newly created VM Instances"
}

output "gcp_vm_instances_name" {
  value       = google_compute_instance.vm_instance[*].name
  description = "The name of the newly created gcp VM Instances"
}

output "gcp_alb_public_ip" {
  description = "The public IP address of the GCP Application Load Balancer"
  value       = google_compute_global_forwarding_rule.lb_frontend_https.ip_address
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke_cluster.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster Endpoint"
  value       = google_container_cluster.gke_cluster.endpoint
}
