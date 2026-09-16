resource "azurerm_capacity_reservation_group" "capacity_reservation_group" {
  name                = "${var.prefix}-capacity-reservation-group"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  zones               = ["1", "2", "3"]
}

resource "azurerm_capacity_reservation" "capacity_reservation" {
  name                          = "${var.prefix}-capacity-reservation"
  capacity_reservation_group_id = azurerm_capacity_reservation_group.capacity_reservation_group.id
  zone                          = var.availability_zone
  sku {
    name     = var.vm_size
    capacity = 1
  }
}
