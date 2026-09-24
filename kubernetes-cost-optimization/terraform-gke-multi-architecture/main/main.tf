module "gcp_cloud_dns_zone" {

source = "../module"
project_name = var.project_name
gcp_region = var.gcp_region[3]
prefix = var.prefix
dns_name = var.dns_name
ip_range_subnet = var.ip_range_subnet
ip_public_range_subnet = var.ip_public_range_subnet
ip_proxy_range_subnet = var.ip_proxy_range_subnet
master_ip_range = var.master_ip_range
pods_ip_range = var.pods_ip_range
services_ip_range = var.services_ip_range
machine_type = var.machine_type
dns_zone_visibility = var.dns_zone_visibility[0]
enable_logging = var.enable_logging[0] 
dnssec_state = var.dnssec_state[0] 
env  = var.env[0]
min_master_version = var.min_master_version[0]
node_version = var.node_version[0]

}
