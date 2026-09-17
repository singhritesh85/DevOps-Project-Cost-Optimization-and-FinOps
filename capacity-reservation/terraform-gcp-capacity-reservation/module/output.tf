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
