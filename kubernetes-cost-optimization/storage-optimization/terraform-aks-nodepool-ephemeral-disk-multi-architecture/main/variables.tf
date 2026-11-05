############################################################### Variables for Azure Resources ########################################################

variable "prefix" {
  description = "Provide the prefix used for the project"
  type        = string
}

variable "subscription_id" {
  description = "Provide Subscription ID of Azure Account"
  type        = string
}

variable "tenant_id" {
  description = "Provide Tenant ID of Azure Account"
  type        = string 
}

variable "env" {
  type        = list(any)
  description = "Provide the Environment for EKS Cluster and NodeGroup"
}

variable "location" {
  type = list
  description = "Provide the Location for Resources to be created"
}

variable "availability_zone" {
  type = list
  description = "Provide the Availability Zone into which the VM to be created"
}

variable "static_dynamic" {
  type = list
  description = "Select the Static or Dynamic"
}

variable "kubernetes_version_aks" {
  type = list
  description = "Provide the Kubernetes Version"
}

variable "action_group_shortname" {
  type = string
  description = "Provide the short name for Azure Action Group"
}

variable "email_address" {
  type = string
  description = "Provide the Group Email Address on which Notification should be send"
}

variable "vm_size" {
  type = list
  description = "Provide the Size of the Azure VM"
}

variable "admin_username" {
  type = string
  description = "Provid the Administrator Username"
}

variable "admin_password" {
  type = string
  description = "Provide the Administrator Password"
}

variable "dns_zone_name" {
  type        = string
  description = "Provide the DNS Zone Name"
}
