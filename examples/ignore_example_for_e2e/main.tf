terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

module "aca_lza_hosting" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  tags             = var.tags
  enable_telemetry = var.enable_telemetry

  workload_name = var.workload_name
  environment   = var.environment

  # Required networking
  spoke_vnet_address_prefixes                     = ["10.30.0.0/16"]
  spoke_infra_subnet_address_prefix               = "10.30.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.30.2.0/24"
  spoke_application_gateway_subnet_address_prefix = "10.30.3.0/24"
  deployment_subnet_address_prefix                = "10.30.4.0/24"

  # VM controls (required variables); keep VM disabled via vm_jumpbox_os_type = "none"
  vm_size                          = "Standard_DS2_v2"
  vm_admin_password                = "P@ssword1234!ChangeMe" # override via TF_VAR in real usage
  vm_jumpbox_subnet_address_prefix = "10.30.5.0/24"
  vm_authentication_type           = "password"
  vm_linux_ssh_authorized_key      = ""
  vm_jumpbox_os_type               = "none"

  # Observability toggles
  enable_application_insights = false
  enable_dapr_instrumentation = false

  # Required by module for Application Gateway path
  application_gateway_certificate_key_name = "${var.workload_name}-cert"
}
