# azure_terraform_acr
Azure container registry creation and import using terraform

This repo has tf files specific to ACR(Azure container registry) creation and import code.

## Senario
Some of ACR is created manually by team and now you need to import this into your terraform state file to make it sync with current state. Additionaly, the ACR which are created are of public access, you need to remove public access and add 'private access' to same.

To enable private access for the Azure Container Registry using Terraform, you'll need to follow these steps:

* Create a private endpoint for the Azure Container Registry.
* Ensure the subnet has the necessary service endpoints.
* Configure the Azure Container Registry to use the private endpoint.

## Solution

* Create dummy section of ACR in existing main.tf, Eg :
```
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
```
Here `devopssample333` is manually created ACR repo with public access, as first step, we need to add `public_network_access_enabled = false` and `network_rule_set {
    default_action = "Deny"
  }`

* Execute `terraform import` command

```
terraform import azurerm_container_registry.acr2 /subscriptions/aaaaa-aaaaa-aaaa-aaaaa-aaaaa/resourceGroups/devops-resources/providers/Microsoft.ContainerRegistry/registries/devopssample333
```
Format : `terraform import azurerm_container_registry.<resource_name> /subscriptions/<your subs ID>/resourceGroups/<your RG name>/providers/Microsoft.ContainerRegistry/registries/<Your ACR repo name>`

* Add relevant section of private_endpoint, dns_record of imported ACR in main.tf

```
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
```
```
resource "azurerm_private_dns_a_record" "acr3_dns" {
  name                = azurerm_container_registry.acr3.name
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300

  records = [azurerm_private_endpoint.acr3_private_endpoint.private_service_connection[0].private_ip_address]
}
```
* Execute terraform commands

```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

