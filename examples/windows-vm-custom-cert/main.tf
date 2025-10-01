terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.0.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Generate a custom certificate for testing
resource "tls_private_key" "cert_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  private_key_pem       = tls_private_key.cert_key.private_key_pem
  validity_period_hours = 8760 # 1 year
  dns_names             = [var.certificate_common_name]

  subject {
    common_name         = var.certificate_common_name
    country             = "US"
    locality            = "Seattle"
    organization        = "Contoso Test Corp"
    organizational_unit = "IT Department"
    province            = "WA"
  }
}

# Convert to PKCS12 format for Azure
resource "pkcs12_from_pem" "cert_pkcs12" {
  password        = var.certificate_password
  cert_pem        = tls_self_signed_cert.cert.cert_pem
  private_key_pem = tls_private_key.cert_key.private_key_pem
}

# Complex scenario: Windows VM with custom certificate and no Application Gateway
module "aca_lza_hosting" {
  source = "../../"

  # Custom certificate configuration (COMPLEX)
  application_gateway_certificate_key_name = var.certificate_key_name
  deployment_subnet_address_prefix         = "10.30.4.0/24"
  # Observability - mixed configuration
  enable_application_insights = true
  enable_dapr_instrumentation = false # Test mixed observability
  # Core - Let module create RG with custom name (COMPLEX)
  location                                        = var.location
  spoke_application_gateway_subnet_address_prefix = "10.30.3.0/24"
  spoke_infra_subnet_address_prefix               = "10.30.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.30.2.0/24"
  # Spoke networking
  spoke_vnet_address_prefixes      = ["10.30.0.0/16"]
  vm_admin_password                = var.vm_admin_password
  vm_jumpbox_subnet_address_prefix = "10.30.5.0/24"
  # Windows VM with password authentication (COMPLEX)
  vm_size                                      = "Standard_DS2_v2"
  application_gateway_certificate_subject_name = "CN=${var.certificate_common_name}"
  application_gateway_fqdn                     = var.certificate_common_name
  base64_certificate                           = pkcs12_from_pem.cert_pkcs12.result
  created_resource_group_name                  = var.resource_group_name
  deploy_agent_pool                            = true
  # No sample app to test minimal deployment
  deploy_sample_application = false
  # No zone redundancy for cost optimization (COMPLEX test case)
  deploy_zone_redundant_resources = false
  # No DDoS protection for cost efficiency
  enable_ddos_protection = false
  enable_telemetry       = var.enable_telemetry
  environment            = var.environment
  # NO Application Gateway - test alternate ingress (COMPLEX)
  expose_container_apps_with = "none"
  # No hub integration - standalone spoke
  hub_virtual_network_resource_id = ""
  network_appliance_ip_address    = ""
  route_spoke_traffic_internally  = true
  tags                            = var.tags
  use_existing_resource_group     = false
  vm_authentication_type          = "password"
  vm_jumpbox_os_type              = "windows"
  vm_linux_ssh_authorized_key     = "" # Not used for Windows
  # Naming
  workload_name = var.workload_name
}




