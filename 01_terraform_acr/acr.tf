resource "azurerm_resource_group" "acr" {
  name     = "rg-acr-${var.ACRNAME}"
  location = (var.LOCATION)
}

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.ACRNAME}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = (var.LOCATION)
  sku                 = "Basic"
  admin_enabled       = true
}
