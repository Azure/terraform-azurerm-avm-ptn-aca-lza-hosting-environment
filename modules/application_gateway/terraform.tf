terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0"
    }
  }
}
