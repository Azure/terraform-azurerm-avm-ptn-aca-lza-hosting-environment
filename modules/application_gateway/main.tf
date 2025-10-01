terraform {
  required_version = ">= 1.6"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115.0"
    }
  }
}

locals {
  zones = var.deploy_zone_redundant_resources ? ["1", "2", "3"] : []
}

# UAI for App Gateway to read Key Vault secret
module "appgw_uai" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "~> 0.2"

  location            = var.location
  name                = var.user_assigned_identity_name
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

# Public IP for Application Gateway
module "appgw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "~> 0.2"

  location             = var.location
  name                 = var.public_ip_name
  resource_group_name  = var.resource_group_name
  allocation_method    = "Static"
  ddos_protection_mode = var.enable_ddos_protection ? "Enabled" : "Disabled"
  diagnostic_settings = var.enable_diagnostics ? {
    diag = {
      name                  = "${var.public_ip_name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["AllMetrics"]
    }
  } : null
  enable_telemetry = var.enable_telemetry
  sku              = "Standard"
  tags             = var.tags
  zones            = local.zones
}

# Certificate module for handling TLS certificates with VNet integration
module "certificate" {
  source = "../certificate"

  app_gateway_principal_id = module.appgw_uai.principal_id
  certificate_key_name     = var.certificate_key_name
  deployment_subnet_id     = var.deployment_subnet_id
  key_vault_id             = var.key_vault_id
  location                 = var.location
  resource_group_name      = var.resource_group_name
  resource_prefix          = substr(replace(var.name, "-", ""), 0, 8)
  storage_account_name     = var.storage_account_name
  base64_certificate       = var.base64_certificate
  certificate_subject_name = var.certificate_subject_name
  tags                     = var.tags
}

# WAF policy - use native resource as AVM equivalent isn't published in TF registry yet
resource "azurerm_web_application_firewall_policy" "waf" {
  location            = var.location
  name                = "${var.name}Policy001"
  resource_group_name = var.resource_group_name
  tags                = var.tags

  managed_rules {
    managed_rule_set {
      version = "3.2"
      type    = "OWASP"
    }
    managed_rule_set {
      version = "0.1"
      type    = "Microsoft_BotManagerRuleSet"
    }
  }
  policy_settings {
    enabled                 = true
    file_upload_limit_in_mb = 10
    mode                    = "Prevention"
  }
}

# Application Gateway using AVM module
module "app_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "~> 0.2"

  backend_address_pools = {
    backend = {
      name  = "acaServiceBackend"
      fqdns = length(trimspace(var.backend_fqdn)) > 0 ? [var.backend_fqdn] : null
    }
  }
  backend_http_settings = {
    https = {
      name                                = "https"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 20
      pick_host_name_from_backend_address = true
      probe_name                          = length(trimspace(var.backend_fqdn)) > 0 ? "webProbe" : null
    }
  }
  # HTTPS only listener on 443
  frontend_ports = {
    https = {
      name = "port_443"
      port = 443
    }
  }
  gateway_ip_configuration = {
    subnet_id = var.subnet_id
  }
  http_listeners = {
    https = {
      name                           = "https-listener"
      host_name                      = length(trimspace(var.application_gateway_fqdn)) > 0 ? var.application_gateway_fqdn : null
      frontend_port_name             = "port_443"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      ssl_certificate_name           = var.certificate_key_name
    }
  }
  location = var.location
  name     = var.name
  request_routing_rules = {
    rule1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "acaServiceBackend"
      backend_http_settings_name = "https"
      priority                   = 100
    }
  }
  resource_group_name                = var.resource_group_name
  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.waf.id
  create_public_ip                   = false
  diagnostic_settings = var.enable_diagnostics ? {
    agw = {
      name                  = "${var.name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  enable_telemetry                      = var.enable_telemetry
  frontend_ip_configuration_public_name = "appGwPublicFrontendIp"
  managed_identities = {
    user_assigned_resource_ids = [module.appgw_uai.resource_id]
  }
  probe_configurations = length(trimspace(var.backend_fqdn)) > 0 ? {
    https = {
      name                                      = "webProbe"
      protocol                                  = "Https"
      host                                      = var.backend_fqdn
      path                                      = var.backend_probe_path
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = false
      match = {
        status_code = ["200-499"]
      }
    }
  } : null
  public_ip_resource_id = module.appgw_pip.resource_id
  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 3
  }
  ssl_certificates = {
    (var.certificate_key_name) = {
      name                = var.certificate_key_name
      key_vault_secret_id = module.certificate.secret_uri
    }
  }
  ssl_policy = {
    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
    ]
  }
  tags  = var.tags
  zones = local.zones
}

# Read the public IP to expose its current address
data "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name

  depends_on = [module.appgw_pip]
}
