output "azure_vm_instance_and_capacity_reservations_details" {
  description = "Details of created Azure VM Instance and Capacity Reservations"
  value       = module.azure_vm 
  sensitive   = true
}
