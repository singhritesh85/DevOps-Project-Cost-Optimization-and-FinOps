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

variable "ip_range_subnet" {
  description = "Provide the IP range for Private Subnet"
  type = string 
}

variable "ip_public_range_subnet" {
  description = "Provide the IP range for Public Subnet"
  type = string
}

variable "machine_type" {
  description = "Provide the Machine Type for VM Instances"
  type = list
}

variable "env" {
  description = "Provide the Environment Name."
  type = list
}
