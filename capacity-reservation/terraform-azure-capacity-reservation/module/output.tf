output "dexter_node_instance_ip" {
  description = "The Private IP of the Dexter Azure VM Instance."
  value       = azurerm_network_interface.vnet_interface_dexter_node.private_ip_address
}
output "dexter_node_public_ip" {
  description = "The public IP address of the Dexter Azure VM instance."
  value       = azurerm_public_ip.public_ip_dexter_node.ip_address
}
output "capacity_reservation_group_id" {
  value       = azurerm_capacity_reservation_group.capacity_reservation_group.id
  description = "The ID of the Azure Capacity Reservation Group."
}
output "capacity_reservation_group_name" {
  value       = azurerm_capacity_reservation_group.capacity_reservation_group.name
  description = "The name of the Azure Capacity Reservation Group."
}
output "capacity_reservation_ids" {
  value       = azurerm_capacity_reservation.capacity_reservation[*].id
  description = "Capacity Reservation IDs."
}
output "capacity_reservation_names" {
  value       = azurerm_capacity_reservation.capacity_reservation[*].name
  description = "Capacity Reservation names."
}
