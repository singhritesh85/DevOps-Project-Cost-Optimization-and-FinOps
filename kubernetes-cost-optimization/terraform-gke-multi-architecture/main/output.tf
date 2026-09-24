output "gke_cluster_gcp_cloud_dns_zone_vm_instances_and_gcp_alb_details" {
  description = "GKE Cluster, GCP Cloud Zone ID, Nameserver, VM Instances IPs and GCP ALB Details"
  value       = "${module.gcp_cloud_dns_zone}"
}
