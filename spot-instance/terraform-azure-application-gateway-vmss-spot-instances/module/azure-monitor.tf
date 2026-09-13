resource "azurerm_log_analytics_workspace" "vmss_log_analytics_workspace" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "mysql" {
  name                       = "${var.prefix}-mysql-diagnostics"
  target_resource_id         = azurerm_mysql_flexible_server.azure_mysql.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.vmss_log_analytics_workspace.id

  enabled_log {
    category = "MySqlSlowLogs"
  }

  enabled_log {
    category = "MySqlAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  name                = "${var.prefix}-mysql-high-cpu"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_mysql_flexible_server.azure_mysql.id]

  description = "Alert when MySQL Flexible Server CPU usage is high"

  severity    = 2
  frequency   = "PT5M"
  window_size = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.mysql.id
  }
}

resource "azurerm_monitor_metric_alert" "mysql_memory" {
  name                = "${var.prefix}-mysql-high-memory"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_mysql_flexible_server.azure_mysql.id]

  description = "Alert when MySQL Flexible Server memory usage is high"

  severity    = 2
  frequency   = "PT5M"
  window_size = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.mysql.id
  }
}

resource "azurerm_monitor_action_group" "mysql" {
  name                = "${var.prefix}-mysql-alerts"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  short_name          = "mysqlalert"

  email_receiver {
    name          = "devops-team"
    email_address = var.email_ids
  }
}

resource "azurerm_monitor_activity_log_alert" "spot_vmss_eviction" {
  name                = "${var.prefix}-spot-vmss-eviction"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = "global"    ###azurerm_resource_group.azure_resource_group.location

  scopes = [
    azurerm_linux_virtual_machine.azure_vm[1].id,
    azurerm_linux_virtual_machine_scale_set.vm_scale_set.id
  ]

  description = "Alert when VM or VMSS resources become unavailable"

  criteria {
    category = "ResourceHealth"

    resource_health {
      current = [
        "Unavailable"
      ]

      reason = [
        "PlatformInitiated"
      ]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.mysql.id
  }
}

resource "azurerm_application_insights" "monitoring" {
  name                = "${var.prefix}-appi-dexter-monitoring"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  application_type    = "web"
  workspace_id = azurerm_log_analytics_workspace.vmss_log_analytics_workspace.id
}

resource "azurerm_application_insights_standard_web_test" "synthetic_monitoring" {
  name                    = "${var.prefix}-synthetic-monitoring"
  resource_group_name     = azurerm_resource_group.azure_resource_group.name
  location                = azurerm_resource_group.azure_resource_group.location
  application_insights_id = azurerm_application_insights.monitoring.id

  description = "Synthetic availability test for Dexter Login WebApp"
  enabled     = false    ### Initially disabled, enable it after the Application Deployment.
  frequency   = 300        ### Run every 5 minutes
  retry_enabled = false  ### Retry once when the first request fails
  timeout     = 30   ### HTTP request timeout

  ### Azure locations from which the synthetic test runs. These IDs are Azure Application Insights test locations.
  geo_locations = [
    "emea-au-syd-edge",  ### Australia East
    "latam-br-gru-edge", ### Brazil South
    "us-fl-mia-edge",    ### Central US
    "apac-hk-hkn-azr",   ### East Asia
    "us-va-ash-azr",     ### East US
    "emea-ch-zrh-edge",  ### France South
    "emea-fr-pra-edge",  ### France Central
    "apac-jp-kaw-edge",  ### Japan East
    "emea-gb-db3-azr",   ### North Europe
    "us-il-ch1-azr",     ### North Central US
    "us-tx-sn1-azr",     ### South Central US
    "apac-sg-sin-azr",   ### Southeast Asia
    "emea-se-sto-edge",  ### UK West
    "emea-nl-ams-azr",   ### West Europe
    "us-ca-sjc-azr",     ### West US
    "emea-ru-msa-edge"   ### UK South
  ]

  request {
    url = "https://dexter.singhritesh85.com/LoginWebApp"
    http_verb = "GET"
    follow_redirects_enabled = true
    parse_dependent_requests_enabled = true
  }

  validation_rules {
    expected_status_code = 200
    ssl_check_enabled = true          ### Validate the TLS certificate
    ssl_cert_remaining_lifetime = 30  ### Fail if certificate has less than 30 days remaining
  }

  tags = {
    application = "dexter"
    environment = "dev"
    monitoring  = "synthetic"
  }
}

resource "azurerm_monitor_metric_alert" "synthetic_monitoring_availability" {
  name                = "${var.prefix}-alert-login-availability"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_application_insights.monitoring.id]
  description = "Alert when Dexter LoginWebApp fails from 3 or more synthetic test locations."
  severity    = 1
  enabled     = true
  frequency   = "PT5M"
  window_size = "PT5M"
  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation = "Average"
    operator    = "LessThan"
    threshold   = 100
  }
  action {
    action_group_id = azurerm_monitor_action_group.mysql.id
  }
  tags = {
    application = "dexter"
    environment = "dev"
  }
}
