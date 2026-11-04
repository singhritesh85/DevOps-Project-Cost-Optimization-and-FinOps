###############################################Create Azure Resource Group###############################################################

resource "azurerm_resource_group" "vnetconnection_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

################################################Create VNet1#############################################################################

resource "azurerm_virtual_network" "vnet-1" {
  name                = "VNet1"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  address_space       = ["10.224.0.0/12"]
}

resource "azurerm_subnet" "vnet1_subnet" {
  name                 = "Subnet-1"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["10.224.0.0/16"]
}

resource "azurerm_subnet" "vnet1_gtwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["10.225.0.0/16"]
}

resource "azurerm_subnet" "mysql_flexible_server_subnet" {
  name                 = "${var.prefix}-mysql-flexible-server-subnet"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["10.226.0.0/16"]
  service_endpoint {
    service = "Microsoft.Storage"
  }
  delegation {
    name = "mysql-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "subnet_se" {
  name                 = "${var.prefix}-acr-subnet"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["10.229.0.0/28"]
}
