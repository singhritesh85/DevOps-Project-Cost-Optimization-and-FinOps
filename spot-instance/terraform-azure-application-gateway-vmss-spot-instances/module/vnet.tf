#################################### Azure VNet, Subnet, NSG and Attachment of NSG to Subent #################################################

resource "azurerm_resource_group" "azure_resource_group" {
  name     = "${var.prefix}-resource-group"
  location = var.location[1]
}

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "acctsub"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.10.1.0/24"]

}

resource "azurerm_subnet" "application_gateway_subnet" {
  name                 = "${var.prefix}-gateway-subnet"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.10.2.0/24"]

}

resource "azurerm_subnet" "mysql_flexible_server_subnet" {
  name                 = "${var.prefix}-mysql-flexible-server-subnet"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.10.3.0/24"]
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

resource "azurerm_subnet" "postgresql_flexible_server_subnet" {
  name                 = "${var.prefix}-postgresql-flexible-server-subnet"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.10.4.0/24"]
  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "appgtw_subnet" {
  name                 = "subnet-1"         ###"${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
#  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.10.5.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "ssh_nsg"
  location            = azurerm_resource_group.azure_resource_group.location          
  resource_group_name = azurerm_resource_group.azure_resource_group.name         

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = [22, 80, 443, 9000, 8080]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

############# NSG has been created and attached to Subnet However It is also possible to create and attach a NSG at Network Interface (NIC) ###############

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association1" {
  subnet_id                 = azurerm_subnet.vmss_subnet.id
  network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}
