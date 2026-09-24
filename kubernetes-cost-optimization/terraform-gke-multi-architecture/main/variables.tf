########################################### Variables to create GCP Resources ################################################

variable "project_name" {
  description = "Provide the project name in GCP Account"
  type = string
}

variable "gcp_region" {
  description = "Provide the GCP Region in which Resources to be created"
  type = list
}

variable "prefix" {
  type = list
  description = "Provide a prefix name for GCP Cloud DNS Zone to be created"
}

variable "dns_name" {
  description = "Provide the name of the Cloud DNS Zone"
  type = string
}

variable "dns_zone_visibility" {
  description = "Select the DNS Zone Visibility between Public and Private"
  type = list
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

variable "master_ip_range" {
  description = "IP address range for the master network of a GKE cluster"
  type = string
}

variable "pods_ip_range" {
  description = "Secondary IP address range using which Pod will be created"
  type        = string
}

variable "services_ip_range" {
  description = "Secondary IP address range using which Services will be created"
  type        = string
}

variable "machine_type" {
  description = "Provide the Machine Type for VM Instances"
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

variable "env" {
  description = "Provide the Environment Name."
  type = list
}

variable "min_master_version" {
  description = "Provide Kubernetes Version of Control Plane"
  type = list
}

variable "node_version" {
  description = "Provide Kubernetes Version of Worker Nodes"
  type = list
}
