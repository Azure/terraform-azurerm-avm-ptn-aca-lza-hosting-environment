terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0, < 5.0.0"
    }
  }
}
