module "azure_vm" {

  source = "../module"
  prefix = var.prefix
  location = var.location[0]
  env = var.env[0]
  static_dynamic = var.static_dynamic 
  availability_zone = var.availability_zone[0]

  vm_size = var.vm_size[4]     ###var.vm_size[0]   ### Standard_F8s_v2 Provides 8 vCPUs and with 16 GiB RAM, Standard_B2s Provides 2 vCPUs and 4 GiB RAM.
  admin_username = var.admin_username
  admin_password = var.admin_password

}  
