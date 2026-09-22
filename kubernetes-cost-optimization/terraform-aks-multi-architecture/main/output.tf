output "aks_k8s_management_and_azure_vm_instance_subnet_id_details" {
  description = "Details of created AKS Cluster, K8S Management Azure VM Instance and Subnet ID"
  value       = module.aks_multiarchitecture 
  sensitive   = true
}
