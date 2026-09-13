############################# Azure Virtual Machine Scale Set with the Uniform Orchestration Mode #########################################
      
resource "azurerm_linux_virtual_machine_scale_set" "vm_scale_set" {
  name                = "mytestscaleset-1"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  instances            = 1
  admin_username       = "ritesh"
  admin_password       = "Password@#795"
  computer_name_prefix = "${var.prefix}"
  custom_data          = filebase64("custom_data.sh")
  sku                  = "Standard_D2s_v5"
  disable_password_authentication = false
  
  overprovision        = false    ###  Default value is true 

# Spot configuration parameters
  priority            = "Spot"
  eviction_policy     = "Deallocate" ### or "Delete"
  max_bid_price       = -1           ### -1 means no eviction based on price alone, up to on-demand price

  # automatic rolling upgrade
# upgrade_mode = "Rolling"     ### Can be used for Ubuntu or Windows Server Operating Systems. 
# automatic_os_upgrade_policy {
#   disable_automatic_rollback = false
#   enable_automatic_os_upgrade = true  ### You can set it to false if needed.
# }

# rolling_upgrade_policy {
#   max_batch_instance_percent              = 20
#   max_unhealthy_instance_percent          = 20
#   max_unhealthy_upgraded_instance_percent = 5
#   pause_time_between_batches              = "PT0S"
# }

# extension {
#   name                       = "HealthExtension"
#   publisher                  = "Microsoft.ManagedServices"
#   type                       = "ApplicationHealthLinux"
#   type_handler_version       = "1.0"
#   auto_upgrade_minor_version = false

#   settings = <<-EOT
#   {
#     "protocol": "http",
#     "port": 8080,
#     "requestPath": "/"
#   }
#   EOT
# }

  # required when using rolling upgrade policy and loadbalancer
#  health_probe_id = azurerm_application_gateway.application_gateway.id

#  source_image_reference {
#    publisher = "OpenLogic"
#    offer     = "CentOS"
#    sku       = "7_9-gen2"
#    version   = "latest"
#  }
 
  source_image_id = var.image_id 

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 32
#    create_option        = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "terraformnetworkprofile"
    primary = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name                                         = "TestIPConfiguration"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.vmss_subnet.id
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.application_gateway.backend_address_pool[*].id
      public_ip_address {
        name = "${var.prefix}-vmss-ip"
        version = "IPv4"  
      }
    }
  }

  boot_diagnostics {
    storage_account_uri = ""
  }

  tags = {
    environment = "staging"
  }
}

############################################## Autoscaling #############################################################

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "VMSS-AutoScaling"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vm_scale_set.id

  profile {
    name = "VMSS-AutoScale-Profile"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vm_scale_set.id
        time_grain         = "PT1M"       ### Metrics should be aggregated every 1 minute.
        statistic          = "Average"
        time_window        = "PT5M"       ### Every time autoscale runs, it queries metrics for the past 5 minutes.
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"        ###  Must be between 1 minute and 1 week. The amount of time to wait since the last scaling action.
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vm_scale_set.id
        time_grain         = "PT1M"      ### Metrics should be aggregated every 1 minute
        statistic          = "Average" 
        time_window        = "PT5M"      ### Every time autoscale runs, it queries metrics for the past 5 minutes.
        time_aggregation   = "Average"   
        operator           = "LessThan"
        threshold          = 20
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"       ### Must be between 1 minute and 1 week. The amount of time to wait since the last scaling action.
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false     ### true
      send_to_subscription_co_administrator = false     ### true
      custom_emails                         = [var.email_ids]
    }
  }
}
