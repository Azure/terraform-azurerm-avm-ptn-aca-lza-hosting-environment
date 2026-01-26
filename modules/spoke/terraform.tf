terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0, < 3.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers - Required for provider inheritance by AVM submodules
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0, < 5.0.0"
    }
  }
}
