terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
