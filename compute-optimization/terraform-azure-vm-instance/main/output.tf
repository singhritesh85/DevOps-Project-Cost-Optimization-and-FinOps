output "azure_vm_instance_details" {
  description = "Details of created Azure VM Instance"
  value       = module.azure_vm 
  sensitive   = true
}
