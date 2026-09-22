output "k8s_management_instance_ip" {
  description = "The Private IP of the K8S Management Azure VM Instance."
  value       = azurerm_network_interface.vnet_interface_k8s_management_node.private_ip_address
}
output "k8s_management_public_ip" {
  description = "The public IP address of the K8S Management Azure VM instance."
  value       = azurerm_public_ip.public_ip_k8s_management_node.ip_address
}
output "aks_cluster_endpoint" {
  description = "Endpoint for Azure AKS Cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.fqdn
}
output "aks_cluster_name" {
  description = "Name of the Azure AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}
output "azure_dns_zone_name" {
  description = "Azure DNS Zone Name"
  value       = azurerm_dns_zone.dns_zone.name
}
output "azure_dns_zone_nameservers" {
  description = "Azure DNS Zone Nameservers"
  value       = azurerm_dns_zone.dns_zone.name_servers
}
output "subnet_id" {
  description = "The ID of the Azure subnet"
  value       = azurerm_subnet.vnet1_subnet.id
}
