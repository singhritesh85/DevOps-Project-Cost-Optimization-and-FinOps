module "autoscale_alb" {

  source = "../module"
  project_name = var.project_name
  gcp_region = var.gcp_region[3]
  prefix = var.prefix
  ip_range_subnet = var.ip_range_subnet
  ip_public_range_subnet = var.ip_public_range_subnet
  ip_proxy_range_subnet = var.ip_proxy_range_subnet
  machine_type = var.machine_type
  database_version = var.database_version[3]
  tier = var.tier[0]
  env = var.env[0]
  source_image = var.source_image
  notification_email = var.notification_email
  db_password = var.db_password

################# To Create GCP Cloud DNS ##################

  dns_name = var.dns_name
  dns_zone_visibility = var.dns_zone_visibility[0]
  enable_logging = var.enable_logging[0] 
  dnssec_state = var.dnssec_state[0] 

}
