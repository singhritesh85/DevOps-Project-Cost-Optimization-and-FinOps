module "aks_multiarchitecture" {

  source = "../module"
  prefix = var.prefix
  location = var.location[1]
  env = var.env[0]
  static_dynamic = var.static_dynamic 
  availability_zone = var.availability_zone[0]

  vm_size = var.vm_size[4]
  admin_username = var.admin_username
  admin_password = var.admin_password

  kubernetes_version_aks = var.kubernetes_version_aks[16]
  action_group_shortname = var.action_group_shortname
  email_address = var.email_address

  dns_zone_name = var.dns_zone_name

}  
