# main.tf

# Configure the Azure provider

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Define the resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Define the virtual network
resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Define the subnet with service endpoints
resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.subnet_address_prefix

  service_endpoints = ["Microsoft.ContainerRegistry"]
}

# Define the Azure Container Registry
resource "azurerm_container_registry" "example" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false

  network_rule_set {
    default_action = "Deny"
  }
}

resource "azurerm_container_registry" "acr2" {
  name                          = "testrg65738"
  resource_group_name           = "devops-resources"
  location                      = "East US"
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
  network_rule_set {
    default_action = "Deny"
  }
}

resource "azurerm_container_registry" "acr3" {
  name                          = "devopssample333"
  resource_group_name           = "devops-resources"
  location                      = "East US"
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
  network_rule_set {
    default_action = "Deny"
  }
}

# Define the private endpoint for the ACR
resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "acr-priv-conn"
    private_connection_resource_id = azurerm_container_registry.example.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}
# Define the private endpoint for ACR2
resource "azurerm_private_endpoint" "acr2_private_endpoint" {
  name                = "acr2-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "acr2-priv-conn"
    private_connection_resource_id = azurerm_container_registry.acr2.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

# Define the private endpoint for ACR2
resource "azurerm_private_endpoint" "acr3_private_endpoint" {
  name                = "acr3-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "acr3-priv-conn"
    private_connection_resource_id = azurerm_container_registry.acr3.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

# Define the private DNS zone
resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.example.name
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

# Add DNS A record for the ACR
resource "azurerm_private_dns_a_record" "example" {
  name                = azurerm_container_registry.example.name
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300

  records = [azurerm_private_endpoint.example.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "acr2_dns" {
  name                = azurerm_container_registry.acr2.name
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300

  records = [azurerm_private_endpoint.acr2_private_endpoint.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "acr3_dns" {
  name                = azurerm_container_registry.acr3.name
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300

  records = [azurerm_private_endpoint.acr3_private_endpoint.private_service_connection[0].private_ip_address]
}
# Output the virtual network ID
output "vnet_id" {
  value = azurerm_virtual_network.example.id
}

# Output the subnet ID
output "subnet_id" {
  value = azurerm_subnet.example.id
}

# Output the container registry ID
output "acr_id" {
  value = azurerm_container_registry.example.id
}

# Output the private endpoint ID
output "private_endpoint_id" {
  value = azurerm_private_endpoint.example.id
}

output "acr2_id" {
  value = azurerm_container_registry.acr2.id
}

output "acr2_private_endpoint_id" {
  value = azurerm_private_endpoint.acr2_private_endpoint.id
}

output "acr3_id" {
  value = azurerm_container_registry.acr3.id
}

output "acr3_private_endpoint_id" {
  value = azurerm_private_endpoint.acr3_private_endpoint.id
}
