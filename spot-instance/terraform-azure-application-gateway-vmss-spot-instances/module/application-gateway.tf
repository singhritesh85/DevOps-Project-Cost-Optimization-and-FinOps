###################################### Azure Application Gateway ###############################################

resource "azurerm_public_ip" "public_ip_gateway" {
  name                = "vmss-public-ip"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  sku                 = "Standard"   ### You can select between Basic and Standard.
  allocation_method   = "Static"     ### You can select between Static and Dynamic.
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = "${var.prefix}-application-gateway"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
#   capacity = 2
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.application_gateway_subnet.id
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feport"
    port = 80
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feporthttps"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.prefix}-gateway-subnet-feip"
    public_ip_address_id = azurerm_public_ip.public_ip_gateway.id
  }

  backend_address_pool {
    name = "${var.prefix}-gateway-subnet-beap"
  }

  backend_http_settings {
    name                  = "${var.prefix}-gateway-subnet-be-htst"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${var.prefix}-gateway-subnet-be-probe-app1"
  }

  probe {
    name                = "${var.prefix}-gateway-subnet-be-probe-app1"
    host                = "sonarqube.singhritesh85.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  }

  http_listener {
    name                           = "${var.prefix}-gateway-subnet-httplstn"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feport"
    protocol                       = "Http"
  }

  # HTTP Routing Rule - HTTP to HTTPS Redirect
  request_routing_rule {
    name                       = "${var.prefix}-gateway-subnet-rqrt"
    priority                   = 101
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-gateway-subnet-httplstn"
#    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap"      ###  It should not be used when redirection of HTTP to HTTPS is configured.
#    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst"   ###  It should not be used when redirection of HTTP to HTTPS is configured.
    redirect_configuration_name = "${var.prefix}-gateway-subnet-rdrcfg"
  }

  # Redirect Config for HTTP to HTTPS Redirect
  redirect_configuration {
    name = "${var.prefix}-gateway-subnet-rdrcfg"
    redirect_type = "Permanent"
    target_listener_name = "${var.prefix}-lstn-https"    ### "${var.prefix}-gateway-subnet-httplstn"
    include_path = true
    include_query_string = true
  }

  # SSL Certificate Block
  ssl_certificate {
    name = "${var.prefix}-certificate"
    password = "Dexter@123"
    data = filebase64("mykey.pfx")
  }

  # HTTPS Listener - Port 443
  http_listener {
    name                           = "${var.prefix}-lstn-https"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feporthttps"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.prefix}-certificate"
  }

  # HTTPS Routing Rule - Port 443
  request_routing_rule {
    name                       = "${var.prefix}-rqrt-https"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-lstn-https"
    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap"
    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst"
  }

}
