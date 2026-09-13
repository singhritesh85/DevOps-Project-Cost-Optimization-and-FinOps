resource "azurerm_private_dns_zone" "dexter_private_mysql" {
  name                = "dexter-mysql.private.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dexter_mysql_vnet_link" {
  name                  = "demoprivate.com"
  private_dns_zone_id   = azurerm_private_dns_zone.dexter_private_mysql.id
  virtual_network_id    = azurerm_virtual_network.vmss_vnet.id
  depends_on            = [azurerm_subnet.mysql_flexible_server_subnet]
}

resource "azurerm_mysql_flexible_server" "azure_mysql" {
  name                   = "dexter-mysql2"
  resource_group_name    = azurerm_resource_group.azure_resource_group.name
  location               = azurerm_resource_group.azure_resource_group.location
  version                = "8.4"   ###"5.7"
  administrator_login    = "adminuser"
  administrator_password = "Admin123"
#  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysql_flexible_server_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dexter_private_mysql.id
  sku_name               = "B_Standard_B1ms"
  zone                   = "2"  

  storage {
    auto_grow_enabled = false
    io_scaling_enabled = false
    iops = 360
    size_gb = 20
  }
  
#  high_availability {
#    mode = "ZoneRedundant"
#    standby_availability_zone = 3
#  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dexter_mysql_vnet_link]
}


resource "azurerm_private_dns_zone" "dexter_private_postgresql" {
  name                = "dexter-postgresql.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dexter_postgresql_vnet_link" {
  name                  = "dexterprivate.com"
  private_dns_zone_id   = azurerm_private_dns_zone.dexter_private_postgresql.id
  virtual_network_id    = azurerm_virtual_network.vmss_vnet.id
  depends_on            = [azurerm_subnet.postgresql_flexible_server_subnet]
}

resource "azurerm_postgresql_flexible_server" "azure_postgresql" {
  name                          = "dexter-postgresql-2"
  resource_group_name           = azurerm_resource_group.azure_resource_group.name
  location                      = azurerm_resource_group.azure_resource_group.location
  version                       = "14"
  delegated_subnet_id           = azurerm_subnet.postgresql_flexible_server_subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.dexter_private_postgresql.id
  public_network_access_enabled = false
  administrator_login           = "postgres"
  administrator_password        = "Admin123"
  zone                          = "1"

#  high_availability {
#    mode = "ZoneRedundant"
#    standby_availability_zone = 2
#  } 

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dexter_postgresql_vnet_link]

}
