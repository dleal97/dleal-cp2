terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.69.0, < 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
