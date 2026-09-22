###################################################### AKS Backup ###############################################################

#data "azurerm_client_config" "current" {}

resource "azurerm_data_protection_backup_vault" "aks_backup_vault" {
  name                = "${var.prefix}-backup-vault"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"  ### "GeoRedundant"  ### "ZoneRedundant"
  soft_delete         = "Off"  ### "On"  ### If enabled, deleted backup items are not immediately and permanently removed.
# retention_duration_in_days = "14"  ### Provide a value between 14 and 180, default value is 14.

  identity {
    type         = "SystemAssigned"
  }
  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "aks_cluster_trusted_access" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  name                  = "${substr(replace(var.prefix, "-", ""), 0, 7)}-trust-role-bind"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = azurerm_data_protection_backup_vault.aks_backup_vault.id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_storage_account" "aks_backup_sa" {
  name                      = "${substr(replace(var.prefix, "-", ""), 0, 10)}backupsa2026"
  resource_group_name       = azurerm_resource_group.vnetconnection_rg.name
  location                  = azurerm_resource_group.vnetconnection_rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"        ### Default TLS Version is TLS1_2.
  shared_access_key_enabled = true
  https_traffic_only_enabled = true
# allowed_copy_scope        = "AAD"   ### Possible values are AAD and PrivateLink                      
  access_tier               = "Hot"
  public_network_access     = "Enabled"
  
  routing {
    choice = "MicrosoftRouting"
  }
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }  
  }

  ### For encryption by default Microsoft-managed keys is used.

  infrastructure_encryption_enabled = false

  tags = {
    environment = var.env
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_storage_container" "aks_sa_container" {
  name                  = "${var.prefix}-container"
  storage_account_id  = azurerm_storage_account.aks_backup_sa.id
  container_access_type = "private"

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_kubernetes_cluster_extension" "aks_cluster_extension" {
  name              = "${var.prefix}-extension"
  cluster_id        = azurerm_kubernetes_cluster.aks_cluster.id
  extension_type    = "Microsoft.DataProtection.Kubernetes"
  release_train     = "stable"
  release_namespace = "dataprotection-microsoft"
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                = azurerm_storage_container.aks_sa_container.name
    "configuration.backupStorageLocation.config.resourceGroup"  = azurerm_resource_group.vnetconnection_rg.name
    "configuration.backupStorageLocation.config.storageAccount" = azurerm_storage_account.aks_backup_sa.name
    "configuration.backupStorageLocation.config.subscriptionId" = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                      = data.azurerm_client_config.current.tenant_id
    "configuration.backupStorageLocation.config.useAAD"         = true
    "configuration.backupStorageLocation.config.storageAccountURI" = azurerm_storage_account.aks_backup_sa.primary_blob_endpoint
  }
  
  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_extension_and_storage_account_permission" {
  scope                = azurerm_storage_account.aks_backup_sa.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.aks_cluster_extension.aks_assigned_identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_vault_msi_read_on_cluster" {
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.aks_backup_vault.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_vault_msi_read_on_snap_rg" {
  scope                = azurerm_resource_group.vnetconnection_rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.aks_backup_vault.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_vault_msi_snapshot_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.vnetconnection_rg.id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = azurerm_data_protection_backup_vault.aks_backup_vault.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_vault_data_operator_on_snap_rg" {
  scope                = azurerm_resource_group.vnetconnection_rg.id
  role_definition_name = "Data Operator for Managed Disks"
  principal_id         = azurerm_data_protection_backup_vault.aks_backup_vault.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_vault_data_contributor_on_storage" {
  scope                = azurerm_storage_account.aks_backup_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.aks_cluster_extension.aks_assigned_identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_role_assignment" "backup_cluster_msi_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.vnetconnection_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "aks_backup_policy" {
  name                = "${var.prefix}-backup-policy"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  vault_name          = azurerm_data_protection_backup_vault.aks_backup_vault.name

  backup_repeating_time_intervals = ["R/2025-08-01T11:00:00+00:00/PT12H"]  ### Repeating backup on the duration of 12 hours.

#  retention_rule {
#    name     = "Daily"
#    priority = 20       ### The lower the priority number, the higher the priority of the rule.

#    life_cycle {
#      duration        = "P30D"   ### Retention duration up to which the backups are to be retained.
#      data_store_type = "OperationalStore"
#    }

#    criteria {
#      absolute_criteria       = "FirstOfDay"
###      days_of_week           = ["Friday"]
###      months_of_year         = ["August"]
###     weeks_of_month         = ["First"]
###      scheduled_backup_times = ["2025-08-01T05:30:00Z"]
#    }
#  }
  
  # Using the default retaintion rule
  default_retention_rule {
    life_cycle {
      duration        = "P30D"
      data_store_type = "OperationalStore"
    }
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "aks_backup_instance" {
  name                         = "${var.prefix}-backup-instance"
  location                     = azurerm_resource_group.vnetconnection_rg.location
  vault_id                     = azurerm_data_protection_backup_vault.aks_backup_vault.id
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks_cluster.id
  snapshot_resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.aks_backup_policy.id

  backup_datasource_parameters {
    excluded_namespaces              = []
    excluded_resource_types          = []
    cluster_scoped_resources_enabled = true
    included_namespaces              = []
    included_resource_types          = []
    label_selectors                  = []
    volume_snapshot_enabled          = true
  }

  depends_on = [
    azurerm_role_assignment.backup_extension_and_storage_account_permission,
    azurerm_role_assignment.backup_vault_msi_read_on_cluster,
    azurerm_role_assignment.backup_vault_msi_read_on_snap_rg,
    azurerm_role_assignment.backup_cluster_msi_contributor_on_snap_rg,
    azurerm_role_assignment.backup_vault_msi_snapshot_contributor_on_snap_rg,
    azurerm_role_assignment.backup_vault_data_operator_on_snap_rg,
    azurerm_role_assignment.backup_vault_data_contributor_on_storage,
    azurerm_data_protection_backup_vault.aks_backup_vault,
    azurerm_data_protection_backup_policy_kubernetes_cluster.aks_backup_policy
  ]
}
