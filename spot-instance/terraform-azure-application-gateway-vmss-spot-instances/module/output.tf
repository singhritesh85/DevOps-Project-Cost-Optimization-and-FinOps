output "azure_dns_zone_name" {
  description = "Azure DNS Zone Name"
  value       = azurerm_dns_zone.dns_zone.name
}

output "azure_dns_zone_nameservers" {
  description = "Azure DNS Zone Nameservers"
  value       = azurerm_dns_zone.dns_zone.name_servers
}

output "application_gateway_sonarqube_id" {
  description = "The ID of the SonarQube Application Gateway."
  value       = azurerm_application_gateway.application_gateway_sonarqube.id
}

output "application_gateway_sonarqube_name" {
  description = "The name of the SonarQube Application Gateway."
  value       = azurerm_application_gateway.application_gateway_sonarqube.name
}

output "frontend_ip_sonarqube_application_gateway" {
  description = "Frontend IP for SonarQube."
  value       = azurerm_public_ip.public_ip_gateway_sonarqube.ip_address
}

output "application_gateway_vmss_application_id" {
  description = "The ID of the VMSS Application Application Gateway."
  value       = azurerm_application_gateway.application_gateway.id
}

output "application_gateway_vmss_application_name" {
  description = "The name of the VMSS Application Application Gateway."
  value       = azurerm_application_gateway.application_gateway.name
}

output "frontend_ip_vmss_application" {
  description = "Frontend IP for VMSS Application."
  value       = azurerm_public_ip.public_ip_gateway.ip_address
}
