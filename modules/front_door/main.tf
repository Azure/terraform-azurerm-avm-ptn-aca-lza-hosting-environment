###############################################
# Front Door module: main implementation     #
###############################################
# This module creates a Front Door with the default *.azurefd.net endpoint
# which uses Microsoft-managed certificates automatically

# Data source to get resource group ID for AzAPI resources
data "azapi_client_config" "current" {}

data "azapi_resource_id" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = var.resource_group_name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
}

# WAF Policy (if enabled and Premium SKU)
resource "azapi_resource" "waf_policy" {
  count = var.enable_waf ? 1 : 0

  location  = "Global"
  name      = var.waf_policy_name
  parent_id = data.azapi_resource_id.resource_group.id
  type      = "Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01"
  body = {
    properties = {
      policySettings = {
        enabledState = "Enabled"
        mode         = "Detection"
      }
      managedRules = {
        managedRuleSets = [
          {
            ruleSetType    = "DefaultRuleSet"
            ruleSetVersion = "1.0"
            ruleSetAction  = "Block"
          },
          {
            ruleSetType    = "Microsoft_BotManagerRuleSet"
            ruleSetVersion = "preview-0.1"
            ruleSetAction  = "Block"
          }
        ]
      }
    }
    sku = {
      name = var.sku_name
    }
  }
  tags = var.tags
}

# Front Door Profile
resource "azapi_resource" "profile" {
  location  = "Global"
  name      = var.name
  parent_id = data.azapi_resource_id.resource_group.id
  type      = "Microsoft.Cdn/profiles@2024-09-01"
  body = {
    sku = {
      name = var.sku_name
    }
    properties = {
      originResponseTimeoutSeconds = 120
    }
  }
  tags = var.tags

  timeouts {
    create = "60m"
    delete = "60m"
    update = "60m"
  }
}

# Front Door Endpoint (uses default *.azurefd.net with Microsoft-managed certificate)
resource "azapi_resource" "endpoint" {
  location  = "Global"
  name      = "${var.name}-endpoint"
  parent_id = azapi_resource.profile.id
  type      = "Microsoft.Cdn/profiles/afdEndpoints@2024-09-01"
  body = {
    properties = {
      enabledState = "Enabled"
    }
  }
  tags = var.tags

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }
}

# Origin Group
resource "azapi_resource" "origin_group" {
  count = var.enable_backend ? 1 : 0

  name      = "${var.name}-origin-group"
  parent_id = azapi_resource.profile.id
  type      = "Microsoft.Cdn/profiles/originGroups@2024-09-01"
  body = {
    properties = {
      loadBalancingSettings = {
        additionalLatencyInMilliseconds = 50
        sampleSize                      = 4
        successfulSamplesRequired       = 2
      }
      healthProbeSettings = {
        probeIntervalInSeconds = 30
        probePath              = var.backend_probe_path
        probeProtocol          = var.backend_protocol
        probeRequestType       = "HEAD"
      }
      sessionAffinityState                                  = "Disabled"
      trafficRestorationTimeToHealedOrNewEndpointsInMinutes = 5
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }
}

# Origin (Backend) - Routes to Container App
# Always uses Private Link for secure connectivity to internal Container Apps Environment
resource "azapi_resource" "origin" {
  count = var.enable_backend ? 1 : 0

  name      = "${var.name}-origin"
  parent_id = azapi_resource.origin_group[0].id
  type      = "Microsoft.Cdn/profiles/originGroups/origins@2024-09-01"
  body = {
    properties = {
      hostName                    = replace(replace(var.backend_fqdn, "https://", ""), "http://", "")
      httpPort                    = 80
      httpsPort                   = var.backend_port
      originHostHeader            = replace(replace(var.backend_fqdn, "https://", ""), "http://", "")
      priority                    = 1
      weight                      = 1000
      enabledState                = "Enabled"
      enforceCertificateNameCheck = true # Required for private link origins


      # Private Link configuration for Container Apps Environment
      # Required for internal Container Apps Environment connectivity
      sharedPrivateLinkResource = {
        privateLinkLocation = var.location
        privateLink = {
          id = var.container_apps_environment_id
        }
        requestMessage = "Front Door Private Link Request for Container App"
        groupId        = "managedEnvironments"
      }
    }
  }
  response_export_values = ["*"]

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }

  lifecycle {
    precondition {
      condition     = var.sku_name == "Premium_AzureFrontDoor"
      error_message = "Private link integration requires Premium_AzureFrontDoor SKU. Current SKU: ${var.sku_name}"
    }
    precondition {
      condition     = var.container_apps_environment_id != null
      error_message = "container_apps_environment_id must be provided for Private Link connectivity."
    }
    precondition {
      condition     = var.backend_fqdn != null
      error_message = "backend_fqdn must be provided when enable_backend is true."
    }
  }
}

# Use null_resource with local-exec to approve the private endpoint connection
# This runs after the origin is created and approves any pending connections
resource "null_resource" "approve_private_endpoint" {
  count = var.enable_backend ? 1 : 0

  # Trigger whenever the origin changes
  triggers = {
    origin_id = azapi_resource.origin[0].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Get all private endpoint connections for the Container Apps Environment
      connections=$(az rest --method get --url "${var.container_apps_environment_id}?api-version=2024-08-02-preview" --query "properties.privateEndpointConnections[?properties.privateLinkServiceConnectionState.status=='Pending'].name" -o tsv)

      # Approve each pending connection
      for conn in $connections; do
        echo "Approving private endpoint connection: $conn"
        az rest --method put \
          --url "${var.container_apps_environment_id}/privateEndpointConnections/$conn?api-version=2024-08-02-preview" \
          --body '{"properties":{"privateLinkServiceConnectionState":{"status":"Approved","description":"Auto-approved by Terraform for Front Door Private Link"}}}'
      done
    EOT
  }

  depends_on = [
    azapi_resource.origin[0]
  ]
}

# Route - Uses the default Front Door endpoint (no custom domain needed)
resource "azapi_resource" "route" {
  count = var.enable_backend ? 1 : 0

  name      = "${var.name}-route"
  parent_id = azapi_resource.endpoint.id
  type      = "Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01"
  body = {
    properties = {
      originGroup = {
        id = azapi_resource.origin_group[0].id
      }
      originPath          = null
      ruleSets            = []
      supportedProtocols  = ["Http", "Https"]
      patternsToMatch     = ["/*"]
      forwardingProtocol  = var.forwarding_protocol
      linkToDefaultDomain = "Enabled"
      httpsRedirect       = "Enabled"
      enabledState        = "Enabled"

      cacheConfiguration = var.caching_enabled ? {
        queryStringCachingBehavior = "IgnoreQueryString"
        queryParameters            = null
        compressionSettings = {
          contentTypesToCompress = [
            "application/eot",
            "application/font",
            "application/font-sfnt",
            "application/javascript",
            "application/json",
            "application/opentype",
            "application/otf",
            "application/pkcs7-mime",
            "application/truetype",
            "application/ttf",
            "application/vnd.ms-fontobject",
            "application/xhtml+xml",
            "application/xml",
            "application/xml+rss",
            "application/x-font-opentype",
            "application/x-font-truetype",
            "application/x-font-ttf",
            "application/x-httpd-cgi",
            "application/x-javascript",
            "application/x-mpegurl",
            "application/x-opentype",
            "application/x-otf",
            "application/x-perl",
            "application/x-ttf",
            "font/eot",
            "font/ttf",
            "font/otf",
            "font/opentype",
            "image/svg+xml",
            "text/css",
            "text/csv",
            "text/html",
            "text/javascript",
            "text/js",
            "text/plain",
            "text/richtext",
            "text/tab-separated-values",
            "text/xml",
            "text/x-script",
            "text/x-component",
            "text/x-java-source"
          ]
          isCompressionEnabled = true
        }
      } : null
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }

  depends_on = [
    azapi_resource.origin[0]
  ]
}

# Security Policy (WAF Association) - Only for Premium SKU
# Note: WAF policy is associated with the default endpoint, not a custom domain
resource "azapi_resource" "security_policy" {
  count = var.enable_waf ? 1 : 0

  name      = "${var.name}-security-policy"
  parent_id = azapi_resource.profile.id
  type      = "Microsoft.Cdn/profiles/securityPolicies@2024-09-01"
  body = {
    properties = {
      parameters = {
        type = "WebApplicationFirewall"
        wafPolicy = {
          id = azapi_resource.waf_policy[0].id
        }
        associations = [
          {
            domains = [
              {
                id = azapi_resource.endpoint.id
              }
            ]
            patternsToMatch = ["/*"]
          }
        ]
      }
    }
  }
}

# Diagnostic Settings
resource "azapi_resource" "diagnostic_settings" {
  count = var.enable_diagnostics ? 1 : 0

  name      = "front-door-diagnostics"
  parent_id = azapi_resource.profile.id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = {
      workspaceId = var.log_analytics_workspace_id
      logs = [
        {
          category = "FrontDoorAccessLog"
          enabled  = true
        },
        {
          category = "FrontDoorHealthProbeLog"
          enabled  = true
        },
        {
          category = "FrontDoorWebApplicationFirewallLog"
          enabled  = true
        }
      ]
      metrics = [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ]
    }
  }
}

# Module telemetry
resource "azurerm_resource_group_template_deployment" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  deployment_mode     = "Incremental"
  name                = "46d3xbcp.ptn.frontdoor.${random_id.telemetry[0].hex}"
  resource_group_name = var.resource_group_name
  template_content = jsonencode({
    "$schema"        = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    "contentVersion" = "1.0.0.0"
    "resources"      = []
  })
}

resource "random_id" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  byte_length = 4
}
