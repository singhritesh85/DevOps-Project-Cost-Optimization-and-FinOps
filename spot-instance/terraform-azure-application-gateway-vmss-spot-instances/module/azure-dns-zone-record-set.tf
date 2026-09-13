resource "azurerm_dns_zone" "dns_zone" {
  name                = "singhritesh85.com"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_a_record" "sonarqube" {
  name                = "sonarqube"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300

  records = [azurerm_public_ip.public_ip_gateway_sonarqube.ip_address]
}

resource "azurerm_dns_a_record" "dexter_recordset" {
  name                = "dexter"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300

  records = [azurerm_public_ip.public_ip_gateway.ip_address]
}
