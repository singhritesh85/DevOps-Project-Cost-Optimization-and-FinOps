module "vmss" {
  source   = "../module"
  prefix   = var.prefix
  location = var.location 
  image_id = var.image_id
  
  vm_count = var.vm_count  
  vm_size = var.vm_size[0]
  availability_zone = var.availability_zone
  static_dynamic = var.static_dynamic
  disk_size_gb = var.disk_size_gb
  extra_disk_size_gb = var.extra_disk_size_gb
  computer_name  = var.computer_name
  admin_username = var.admin_username
  admin_password = var.admin_password
  email_ids = var.email_ids

  env = var.env[0]

}
