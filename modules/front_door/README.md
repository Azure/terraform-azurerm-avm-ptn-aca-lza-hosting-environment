# Front Door Module

This module creates an Azure Front Door (Standard or Premium) with custom domain support and TLS termination using certificates from Azure Key Vault.

## Features

- Azure Front Door Standard or Premium SKU
- Custom domain configuration with TLS termination
- Certificate management via Azure Key Vault
- Optional Web Application Firewall (Premium SKU only)
- Health probes for backend monitoring
- Diagnostic logging to Log Analytics
- Caching support with compression

## Requirements

- Azure Key Vault with a certificate stored under the specified certificate key name
- User Assigned Identity with access to the Key Vault
- Backend endpoint (Container Apps Environment default domain)

## Usage

```hcl
module "front_door" {
  source = "./modules/front_door"

  name                = "my-front-door"
  resource_group_name = "my-rg"
  location            = "East US"
  
  # SKU Configuration
  sku_name = "Standard_AzureFrontDoor"
  
  # Domain and Certificate
  front_door_fqdn       = "app.contoso.com"
  certificate_key_name  = "app-contoso-com-cert"
  key_vault_id         = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.KeyVault/vaults/xxx"
  
  # Backend Configuration
  backend_fqdn     = "my-aca-env.eastus.azurecontainerapps.io"
  backend_protocol = "Https"
  backend_port     = 443
  
  # Identity
  user_assigned_identity_name = "front-door-identity"
  
  # Optional Features
  enable_waf      = false
  caching_enabled = true
  
  # Diagnostics
  log_analytics_workspace_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.OperationalInsights/workspaces/xxx"
  
  tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Front Door profile name | `string` | n/a | yes |
| resource_group_name | Resource group name to deploy resources into | `string` | n/a | yes |
| location | Azure region for resources | `string` | n/a | yes |
| front_door_fqdn | The custom domain FQDN for the Front Door endpoint | `string` | n/a | yes |
| backend_fqdn | The backend FQDN that Front Door will route traffic to | `string` | n/a | yes |
| certificate_key_name | The name of the certificate key in Key Vault for TLS termination | `string` | n/a | yes |
| key_vault_id | The resource ID of the Key Vault containing the TLS certificate | `string` | n/a | yes |
| user_assigned_identity_name | Name of the User Assigned Identity used by Front Door to read Key Vault secrets | `string` | n/a | yes |
| sku_name | SKU name for the Front Door profile | `string` | `"Standard_AzureFrontDoor"` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |
| enable_telemetry | Enable module telemetry | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostic settings | `string` | `""` | no |
| enable_waf | Enable Web Application Firewall. Requires Premium SKU | `bool` | `false` | no |
| waf_policy_name | Name of the WAF policy. Required if enable_waf is true | `string` | `""` | no |
| backend_probe_path | Health probe path for backend health checks | `string` | `"/"` | no |
| backend_protocol | Protocol for backend communication | `string` | `"Https"` | no |
| backend_port | Port for backend communication | `number` | `443` | no |
| caching_enabled | Enable caching for the route | `bool` | `true` | no |
| forwarding_protocol | Protocol to use when forwarding traffic to backends | `string` | `"MatchRequest"` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Front Door profile resource ID |
| name | Front Door profile name |
| endpoint_hostname | Front Door endpoint hostname |
| custom_domain_fqdn | Custom domain FQDN configured for Front Door |
| origin_group_id | Front Door origin group resource ID |
| endpoint_id | Front Door endpoint resource ID |
| waf_policy_id | WAF policy resource ID (if enabled) |

## Notes

- The certificate must be stored in the specified Key Vault before deploying this module
- WAF features are only available with Premium SKU
- Custom domains require DNS configuration to point to the Front Door endpoint
- The User Assigned Identity needs appropriate permissions to access the Key Vault certificate