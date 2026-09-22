############################################## Creation for NSG for K8S Management Node #######################################################

resource "azurerm_network_security_group" "azure_nsg_k8s_management_node" {
#  count               = var.vm_count_rabbitmq
  name                = "k8s-management-node-nsg"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  security_rule {
    name                       = "k8s_management_node_ssh_azure"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env
  }
}

########################################## Create Public IP and Network Interface for K8S Management Node #############################################

resource "azurerm_public_ip" "public_ip_k8s_management_node" {
#  count               = var.vm_count_rabbitmq
  name                = "k8s-management-node-ip"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  allocation_method   = var.static_dynamic[0]

  sku = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard
  zones = [var.availability_zone]

  tags = {
    environment = var.env
  }
}

resource "azurerm_network_interface" "vnet_interface_k8s_management_node" {
#  count               = var.vm_count_rabbitmq
  name                = "k8s-management-node-nic"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  ip_configuration {
    name                          = "k8s-management-node-ip-configuration"
    subnet_id                     = azurerm_subnet.vnet1_subnet.id
    private_ip_address_allocation = var.static_dynamic[1]
    public_ip_address_id = azurerm_public_ip.public_ip_k8s_management_node.id
  }

  tags = {
    environment = var.env
  }
}

############################################ Attach NSG to Network Interface for K8S Management Node #####################################################

resource "azurerm_network_interface_security_group_association" "nsg_nic" {
#  count                     = var.vm_count_rabbitmq
  network_interface_id      = azurerm_network_interface.vnet_interface_k8s_management_node.id
  network_security_group_id = azurerm_network_security_group.azure_nsg_k8s_management_node.id

}

######################################################## Create Azure VM for K8S Management Node ##########################################################

resource "azurerm_linux_virtual_machine" "azure_vm_k8s_management_node" {
#  count                 = var.vm_count_rabbitmq
  name                  = "k8s-management-node-vm"
  location              = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name   = azurerm_resource_group.vnetconnection_rg.name
  network_interface_ids = [azurerm_network_interface.vnet_interface_k8s_management_node.id]
  size                  = var.vm_size
  zone                 = var.availability_zone
  computer_name  = "k8s-management-node-vm"
  admin_username = var.admin_username
  admin_password = var.admin_password
  custom_data    = filebase64("custom_data.sh")
  disable_password_authentication = false

  #### Boot Diagnostics is Enable with managed storage account ########
  boot_diagnostics {
    storage_account_uri  = ""
  }

  source_image_reference {
    publisher = "almalinux"      ###"OpenLogic"
    offer     = "almalinux-x86_64"      ###"CentOS"
    sku       = "8-gen2"         ###"7_9-gen2"
    version   = "latest"         ###"latest"
  }
  os_disk {
    name              = "k8s-management-node-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = 32
  }

#  identity {
#    type         = "UserAssigned"
#    identity_ids = [azurerm_user_assigned_identity.uai_push_acr_images.id]
#  }

  tags = {
    environment = var.env
  }

  depends_on = [azurerm_managed_disk.disk_k8s_management_node]

}

resource "azurerm_managed_disk" "disk_k8s_management_node" {
#  count                = var.vm_count_rabbitmq
  name                 = "k8s-management-node-datadisk"
  location             = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  zone                 = var.availability_zone
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}


resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment_k8s_management_node" {
#  count              = var.vm_count_rabbitmq
  managed_disk_id    = azurerm_managed_disk.disk_k8s_management_node.id
  virtual_machine_id = azurerm_linux_virtual_machine.azure_vm_k8s_management_node.id
  lun                = "0"
  caching            = "ReadWrite"
}

###################################################### Azure VM Backup ######################################################

resource "random_id" "id3" {
  byte_length = 4
}

resource "azurerm_recovery_services_vault" "recovery_svc_vault" {
  name                = "${var.prefix}-recovery-vault"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "azure_vm_backup_policy" {
  name                = "${var.prefix}-recovery-vault-policy"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.recovery_svc_vault.name
  policy_type = "V2"  ### V2 shows Enhanced type which leverage Multiple backups per day.

  timezone = "UTC"

  backup {
    frequency = "Hourly"
    time      = "17:30"
    hour_interval = "12"
    hour_duration = "24"
  }

  instant_restore_retention_days = 7
  instant_restore_resource_group {
    prefix = "${var.prefix}-backup"
    suffix = random_id.id3.hex
  }

  retention_daily {
    count = 30
  }
}

resource "azurerm_backup_protected_vm" "devops_agent_vm" {
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.recovery_svc_vault.name
  source_vm_id        = azurerm_linux_virtual_machine.azure_vm_k8s_management_node.id
  backup_policy_id    = azurerm_backup_policy_vm.azure_vm_backup_policy.id
}
