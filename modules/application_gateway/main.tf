
# Get current Azure context for constructing resource IDs
data "azapi_client_config" "current" {}

locals {
  zones                = var.deploy_zone_redundant_resources ? ["1", "2", "3"] : []
  has_backend          = var.enable_backend
  certificate_password = local.has_backend ? random_password.cert_password[0].result : ""
  # Strip protocol from backend FQDN for Application Gateway compatibility
  backend_fqdn_clean = replace(replace(var.backend_fqdn, "https://", ""), "http://", "")
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

# Generate a secure random password for the certificate
resource "random_password" "cert_password" {
  count = local.has_backend ? 1 : 0

  length  = 24
  special = true
}

# Generate a simple self-signed certificate for demo purposes
# This avoids the complexity of Key Vault integration for a hosting environment module
# Only created when a backend is configured (demo app deployed)
resource "tls_private_key" "appgw" {
  count = local.has_backend ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "appgw" {
  count = local.has_backend ? 1 : 0

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  private_key_pem       = tls_private_key.appgw[0].private_key_pem
  validity_period_hours = 8760 # 1 year

  subject {
    common_name  = "aca-demo.local"
    organization = "Azure Container Apps Demo"
  }
}

# Convert to PKCS12 format for Application Gateway
resource "pkcs12_from_pem" "appgw" {
  count = local.has_backend ? 1 : 0

  password        = random_password.cert_password[0].result
  cert_pem        = tls_self_signed_cert.appgw[0].cert_pem
  private_key_pem = tls_private_key.appgw[0].private_key_pem
}

# WAF policy - migrated to AzAPI for AVM v1.0 compliance
resource "azapi_resource" "waf" {
  type      = "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2024-01-01"
  name      = "${var.name}Policy001"
  location  = var.location
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = var.tags

  body = {
    properties = {
      managedRules = {
        managedRuleSets = [
          {
            ruleSetType    = "OWASP"
            ruleSetVersion = "3.2"
          },
          {
            ruleSetType    = "Microsoft_BotManagerRuleSet"
            ruleSetVersion = "0.1"
          }
        ]
      }
      policySettings = {
        state               = "Enabled"
        mode                = "Prevention"
        fileUploadLimitInMb = 10
      }
    }
  }

  schema_validation_enabled = true
  ignore_casing             = true
  ignore_missing_property   = true

  response_export_values = ["*"]
}

locals {
  # Normalize the WAF policy ID to use lowercase resource type segment for AzureRM provider compatibility
  waf_policy_id = replace(azapi_resource.waf.id, "ApplicationGatewayWebApplicationFirewallPolicies", "applicationGatewayWebApplicationFirewallPolicies")
}

# Application Gateway using AVM module
module "app_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "~> 0.2"

  backend_address_pools = {
    backend = {
      name  = "acaServiceBackend"
      fqdns = local.has_backend ? [local.backend_fqdn_clean] : null
    }
  }
  backend_http_settings = {
    https = {
      name                                = "https"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 20
      pick_host_name_from_backend_address = true
      probe_name                          = local.has_backend ? "webProbe" : null
    }
  }
  # Frontend ports - only HTTPS when backend is configured, otherwise HTTP for infrastructure only
  frontend_ports = local.has_backend ? {
    https = {
      name = "port_443"
      port = 443
    }
    } : {
    http = {
      name = "port_80"
      port = 80
    }
  }
  gateway_ip_configuration = {
    subnet_id = var.subnet_id
  }
  http_listeners = local.has_backend ? {
    https = {
      name                           = "https-listener"
      frontend_port_name             = "port_443"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      ssl_certificate_name           = "appgw-demo-cert"
      protocol                       = "Https"
    }
    } : {
    http = {
      name                           = "http-listener"
      frontend_port_name             = "port_80"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      protocol                       = "Http"
    }
  }
  location = var.location
  name     = var.name
  request_routing_rules = {
    rule1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = local.has_backend ? "https-listener" : "http-listener"
      backend_address_pool_name  = "acaServiceBackend"
      backend_http_settings_name = "https"
      priority                   = 100
    }
  }
  resource_group_name                = var.resource_group_name
  app_gateway_waf_policy_resource_id = local.waf_policy_id
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
  probe_configurations = local.has_backend ? {
    https = {
      name                                      = "webProbe"
      protocol                                  = "Https"
      host                                      = local.backend_fqdn_clean
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
  ssl_certificates = local.has_backend ? {
    "appgw-demo-cert" = {
      name     = "appgw-demo-cert"
      data     = pkcs12_from_pem.appgw[0].result
      password = local.certificate_password
    }
  } : null
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
