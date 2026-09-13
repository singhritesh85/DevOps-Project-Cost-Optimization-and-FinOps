output "dns_zone_nameservers_and_application_gateway" {
  description = "Details of created DNS Zone Nameservers and Application Gateway Details"
  value       = module.vmss
  sensitive   = true
}
