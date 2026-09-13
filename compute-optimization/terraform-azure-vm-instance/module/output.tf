output "dexter_node_instance_ip" {
  description = "The Private IP of the Dexter Azure VM Instance."
  value       = azurerm_network_interface.vnet_interface_dexter_node.private_ip_address
}
output "dexter_node_public_ip" {
  description = "The public IP address of the Dexter Azure VM instance."
  value       = azurerm_public_ip.public_ip_dexter_node.ip_address
}
