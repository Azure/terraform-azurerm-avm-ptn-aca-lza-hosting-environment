terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = ">= 0.3.0, < 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1, < 4.0"
    }
  }
}
