######################################## Create an Action Group for Email Notifications ####################################

#resource "azurerm_monitor_action_group" "spot_eviction_alert" {
#  name                = "aks-spot-eviction-action-group"
#  resource_group_name = var.resource_group_name
#  short_name          = "SpotEviction"

#  email_receiver {
#    name                    = "OperationsTeam"
#    email_address           = "ops-team@yourdomain.com"
#    use_common_alert_schema = true
#  }
#}

################################### Create an Activity Log Alert for Spot Evictions ########################################

resource "azurerm_monitor_activity_log_alert" "spot_instant_eviction" {
  name                = "${var.prefix}-aks-spot-instant-eviction-alert"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = "global"

  scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.aks_cluster.node_resource_group}"
  ]

  criteria {
    category       = "Administrative"
    # Restrict strictly to deallocate actions (covers both Spot evictions and manual stops)
    operation_name = "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/deallocate/action"
    status         = "Succeeded"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }

  description = "Notification when an AKS Spot node is reclaimed by Azure."
}
