#############################################################################################################################
# Provision AKS Cluster
#############################################################################################################################

# Data source to access the configuration of the AzureRM provider
data "azurerm_client_config" "current" {}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "insights" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Manage a Log Analytics Solutions
resource "azurerm_log_analytics_solution" "container_insight" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name   = azurerm_resource_group.vnetconnection_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.insights.id
  workspace_name        = azurerm_log_analytics_workspace.insights.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Generate random string of byte length 16
resource "random_id" "id1" {
  byte_length = 16
}

# Generate random string of byte lengh 8
resource "random_id" "id2" {
  byte_length = 8
}

# Create private dns zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "${random_id.id1.hex}.privatelink.eastus2.azmk8s.io"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
}

# Create virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.prefix}-cluster-dns-${random_id.id2.hex}"
  private_dns_zone_id = azurerm_private_dns_zone.private_dns_zone.id
  virtual_network_id    = azurerm_virtual_network.vnet-1.id
}

# Create user assigned identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-uai"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
}

# Identity role assignment
resource "azurerm_role_assignment" "dns_contributor" {
  scope                = azurerm_private_dns_zone.private_dns_zone.id
  role_definition_name = "Contributor"   ### "Private DNS Zone Contributor" Role can also be assigned
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_vnet_subnet" {
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name = "Contributor"     ### "Network Contributor" Role can also be assigned
  scope                = azurerm_subnet.vnet1_subnet.id
#  depends_on = [azurerm_monitor_metric_alert.alert_rule1, azurerm_monitor_metric_alert.alert_rule2]
}

# Create Azure Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-cluster"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  dns_prefix          = "${var.prefix}-cluster-dns"
  kubernetes_version  = var.kubernetes_version_aks
  node_resource_group = "${var.prefix}-noderg"
  sku_tier            = "Standard"
  private_cluster_enabled = true
  azure_policy_enabled = true
  private_dns_zone_id = azurerm_private_dns_zone.private_dns_zone.id
  
  default_node_pool {
    name                 = "systempool"
    vm_size              = "Standard_D4ps_v6"  ###"Standard_B4ms"   ###"Standard_B2ms"   ###"Standard_B2s"  ###"Standard_DS3_v2" ###Standard_DS2_v2
    orchestrator_version = var.kubernetes_version_aks
#    zones                = [1, 2, 3]
#    enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
#    auto_scaling_enabled = true
    host_encryption_enabled = true     ### Enable Host-Based Encryption
#    max_count            = 3
    node_count           = 1
#    min_count            = 1
    max_pods             = 110
    os_disk_type         = "Managed"
    os_disk_size_gb      = 30
    os_sku               = "Ubuntu"    ### You can select between Ubuntu and AzureLinux.
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.vnet1_subnet.id
    upgrade_settings {
      max_surge = "10%"
    }
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
    tags = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
  }

  automatic_upgrade_channel = "stable"
  node_os_upgrade_channel   = "NodeImage"
  maintenance_window_auto_upgrade {
      frequency   = "RelativeMonthly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      week_index  = "First"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }
  maintenance_window_node_os {
      frequency   = "Weekly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }


# Identity (System Assigned or Service Principal)
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }
#  identity {
#    type = "SystemAssigned"
#  }

### Storage Profile Block
  storage_profile {
    blob_driver_enabled = false                   ### Provide the boolean to enable or disable the Blob CSI Driver. Default value is false.
    disk_driver_enabled = true                    ### Provide the boolean to enable or disable the Disk CSI Driver. Default value is true.
    #disk_driver_version = "v1"                    ### Disk driver version v2 is in public review. Default version is v1.
    file_driver_enabled = true                    ### Provide the boolean to enable or disable the File CSI Driver. Default value is true.
    snapshot_controller_enabled = true            ### Provide the boolean to enable or disable the Snapshot Controller. Default value is true.
  }


### Linux Profile
#  linux_profile {
#    admin_username = "ritesh"
#    ssh_key {
#      key_data = file(var.ssh_public_key)
#    }
#  }

# Network Profile
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"   ###"azure"   ### default value is azure.
    load_balancer_sku   = "standard"
    service_cidr        = "10.0.0.0/16"  ### Kubernetes service address range
    dns_service_ip      = "10.0.0.10"    ### Kubernetes DNS service IP address
  }

# ENABLE NODE AUTO-PROVISIONING (KARPENTER)
  node_provisioning_profile {
    mode                        = "Auto" # Enables Azure-managed Karpenter
    default_node_pools          = "None" # Automatically creates default & system-surge Karpenter NodePools
  }

# Enable KEDA and VPA 
  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  monitor_metrics {
  
  }

  oms_agent {
#    enabled =  true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
  count                        = 2    ###var.enable_auto_scaling ? 1 : 0
  name                         = count.index == 0 ? "cobaltpool" : "spotamd64"
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks_cluster.id
#  zones                        = [1, 2, 3]
  orchestrator_version = var.kubernetes_version_aks
  vm_size  = count.index == 0 ? "Standard_D4ps_v6" : "Standard_B4as_v2"
  mode                         = "User"          ### You can select between System and User
# enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
#  auto_scaling_enabled = true
  host_encryption_enabled = true    ### Enable Host-Based Encryption
#  max_count            = 3
  node_count           = 1
#  min_count            = 1
  max_pods             = 110
  os_disk_type         = "Managed"
  os_disk_size_gb      = 30  
  os_type              = "Linux"
  os_sku               = "Ubuntu"        ### You can select between Ubuntu and AzureLinux.
#  type                 = "VirtualMachineScaleSets"
  vnet_subnet_id       = azurerm_subnet.vnet1_subnet.id
  ### Spot specific configurations start here ###
  priority        = count.index == 0 ? "Regular" : "Spot"
  eviction_policy = count.index == 0 ? null : "Delete"
  spot_max_price  = count.index == 0 ? null : -1 ### Pay up to the on-demand price
  ### Spot specific configurations end here   ###
  dynamic "upgrade_settings" {
    for_each = count.index == 0 ? [1] : []
    content {
      max_surge = "10%" # Replace with your existing max_surge value
    }
  }
  node_labels = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
  tags = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
} 

##########################################################################################################################################

resource "azurerm_monitor_action_group" "action_group" {
  name                = "${var.prefix}-action-group"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = "global"
  short_name          = var.action_group_shortname

  email_receiver {
    name          = "GroupNotification"
    email_address = var.email_address
  }
}

resource "azurerm_monitor_metric_alert" "alert_rule1" {
  name                = "${var.prefix}-alert-rule1"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  scopes              = [azurerm_kubernetes_cluster.aks_cluster.id]
  description         = "Email will be triggered when Percentage CPU Utilization is greater than 80%"
  auto_mitigate       = true    ### Metric Alert to be auto resolved when the Alert Condition is no loger met.
  frequency           = "PT5M"


  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
   
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

#######################################################################################################
# Create Kubeconfig file 
#######################################################################################################

resource "null_resource" "kubectl_aks" {
    provisioner "local-exec" {
        command = "az account set --subscription $(az account show --query id|tr -d '\"') && az aks get-credentials --resource-group ${azurerm_resource_group.vnetconnection_rg.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --overwrite-existing && chmod 600 ~/.kube/config"
        interpreter = ["/bin/bash", "-c"]
    }

    depends_on = [azurerm_kubernetes_cluster.aks_cluster, azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

#######################################################################################################
# Authorization for VNet Subnet
#######################################################################################################

#resource "azurerm_role_assignment" "aks_vnet_subnet2" {
#  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
#  role_definition_name = "Contributor"
#  scope                = azurerm_subnet.aks_subnet.id
#  depends_on = [azurerm_monitor_metric_alert.alert_rule1, azurerm_monitor_metric_alert.alert_rule2]
#}

