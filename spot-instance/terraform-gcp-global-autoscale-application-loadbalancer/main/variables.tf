variable "project_name" {
  description = "Provide the project name in GCP Account"
  type = string
}

variable "gcp_region" {
  description = "Provide the GCP Region in which Resources to be created"
  type = list
}

variable "prefix" {
  description = "Provide the prefix used for the project"
  type = string
}

variable "ip_range_subnet" {
  description = "Provide the IP range for Private Subnet"
  type = string 
}

variable "ip_public_range_subnet" {
  description = "Provide the IP range for Public Subnet"
  type = string
}

variable "ip_proxy_range_subnet" {
  description = "Provide the IP range for Proxy Subnet will be used by GCP ALB"
  type = string
}

variable "machine_type" {
  description = "Provide the Machine Type for VM Instances"
  type = list
}

variable "database_version" {
  description = "Provide the database version DB Instance"
  type = list
}

variable "tier" {
  description = "Provide the Machine Type for VM Instances"
  type = list
}

variable "env" {
  type = list
  description = "Provide the Environment for Cloud Instrastructure"
}

variable "notification_email" {
  type = string
  description = "Provide the Group Email ID on which the Email to be sent."
}

variable "db_password" {
  type = string
  description = "Provide the MySQL DB Password"
  sensitive   = true
}

####################################### Variables to create GCP Cloud DNS ################################################

variable "dns_name" {
  description = "Provide the DNS Name"
  type = string
}

variable "dns_zone_visibility" {
  description = "Select the DNS Zone Visibility between Public and Private"
  type = list
}

variable "enable_logging" {
  description = "Select do you want to enable or disable the logging"
  type = list
}

variable "dnssec_state" {
  description = "Select do you want to enable or disable the dnssec"
  type = list
}
