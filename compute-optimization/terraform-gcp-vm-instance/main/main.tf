module "gcp_vm_instance" {

source = "../module"
project_name = var.project_name
gcp_region = var.gcp_region[2]
prefix = var.prefix
ip_range_subnet = var.ip_range_subnet
ip_public_range_subnet = var.ip_public_range_subnet
machine_type = var.machine_type
env  = var.env[0]

}
