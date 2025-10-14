# AzAPI Provider Migration Plan for AVM v1.0 Compliance

## Executive Summary

To achieve AVM v1.0 certification, this module must migrate from the AzureRM provider to the AzAPI provider for all direct Azure resource management. The AzAPI provider is Microsoft-owned and provides day-0/day-1 support for new Azure features, making it the required standard for AVM modules.

**Migration Scope**: This document identifies all direct AzureRM provider usage and provides a detailed migration plan. AVM module dependencies (which already use AzureRM internally) will remain unchanged per AVM guidelines.

**🎯 No Breaking Changes Concern**: This module has not been released yet, so we can perform a clean replacement without worrying about existing users, state migration, or moved blocks. This is a straightforward rip-and-replace operation.

---

## Impact Assessment

### Modules Requiring Migration

#### 1. **Front Door Module** (`modules/front_door/`)
   - **Complexity**: HIGH
   - **Effort**: 2-3 days
   - **Priority**: P0 (Core functionality for public-facing Container Apps)

#### 2. **Application Gateway Module** (`modules/application_gateway/`)
   - **Complexity**: MEDIUM
   - **Effort**: 1-2 days
   - **Priority**: P0 (Alternative ingress option)

#### 3. **Supporting Services - Key Vault** (`modules/supporting_services/key_vault/`)
   - **Complexity**: LOW
   - **Effort**: 2-4 hours
   - **Priority**: P1 (Data source only)

---

## Detailed Resource Inventory

### 1. Front Door Module (`modules/front_door/main.tf`)

**Current AzureRM Resources (8 total):**

| Resource Type | Resource Name | Lines | Complexity | Priority |
|--------------|---------------|-------|------------|----------|
| `azurerm_cdn_frontdoor_profile` | `this` | 31-37 | Medium | P0 |
| `azurerm_cdn_frontdoor_endpoint` | `this` | 40-46 | Low | P0 |
| `azurerm_cdn_frontdoor_origin_group` | `this` | 48-65 | Medium | P0 |
| `azurerm_cdn_frontdoor_origin` | `this` | 69-101 | High | P0 |
| `azurerm_cdn_frontdoor_route` | `this` | 131-196 | High | P0 |
| `azurerm_cdn_frontdoor_firewall_policy` | `this` | 8-29 | Medium | P1 |
| `azurerm_cdn_frontdoor_security_policy` | `this` | 198-218 | Medium | P1 |
| `azurerm_monitor_diagnostic_setting` | `front_door` | 220-240 | Low | P2 |

**Special Considerations:**
- **Private Link Configuration**: Lines 83-88 contain critical private link setup for Container Apps
- **Dynamic Cache Block**: Lines 145-195 contain complex dynamic caching configuration
- **WAF Integration**: Conditional resources based on `var.enable_waf`
- **Lifecycle Preconditions**: Lines 91-100 enforce SKU requirements

**AzAPI Resource Types Required:**
```terraform
# Microsoft.Cdn/profiles@2024-02-01
# Microsoft.Cdn/profiles/afdEndpoints@2024-02-01
# Microsoft.Cdn/profiles/originGroups@2024-02-01
# Microsoft.Cdn/profiles/originGroups/origins@2024-02-01
# Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01
# Microsoft.Cdn/profiles/securityPolicies@2024-02-01
# Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01
# Microsoft.Insights/diagnosticSettings@2021-05-01-preview
```

### 2. Application Gateway Module (`modules/application_gateway/main.tf`)

**Current AzureRM Resources (2 direct resources):**

| Resource Type | Resource Name | Lines | Complexity | Priority |
|--------------|---------------|-------|------------|----------|
| `azurerm_web_application_firewall_policy` | `waf` | 59-78 | Low | P0 |
| `data.azurerm_public_ip` | `pip` | 188-193 | Low | P0 |

**Special Considerations:**
- Uses AVM module `avm-res-network-applicationgateway` for main App Gateway (NO MIGRATION NEEDED)
- Uses AVM module `avm-res-network-publicipaddress` for Public IP (NO MIGRATION NEEDED)
- Only WAF policy and data source require migration
- TLS certificate generation using `tls_private_key`, `tls_self_signed_cert`, and `pkcs12_from_pem` (NO CHANGE)

**AzAPI Resource Types Required:**
```terraform
# Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01
# Data source: Microsoft.Network/publicIPAddresses@2024-01-01
```

### 3. Key Vault Module (`modules/supporting_services/key_vault/main.tf`)

**Current AzureRM Resources (1 data source):**

| Resource Type | Resource Name | Lines | Complexity | Priority |
|--------------|---------------|-------|------------|----------|
| `data.azurerm_client_config` | `current` | 15 | Low | P0 |

**Special Considerations:**
- Used to get current tenant_id, object_id, and client_id for Key Vault RBAC
- Uses AVM module `avm-res-keyvault-vault` for main Key Vault (NO MIGRATION NEEDED)
- Uses AVM module `avm-res-network-privatednszone` for DNS (NO MIGRATION NEEDED)
- Logic to detect User vs ServicePrincipal based on client_id (lines 6-13)

**AzAPI Alternative:**
```terraform
# No direct AzAPI equivalent for client_config
# Options:
# 1. Use azapi_client_config data source (if available)
# 2. Pass tenant_id/object_id as variables from root module
# 3. Use terraform data sources from azuread provider
```

---

## Resources Excluded from Migration (AVM Modules)

The following resources use AVM modules and **DO NOT** require migration:

### Root Module (`main.tf`)
- `module.spoke` - Uses AVM pattern internally
- `module.supporting_services` - Wrapper around AVM modules
- `module.container_apps_environment` - Uses AVM modules
- `module.sample_application` - Uses AVM modules
- `module.application_gateway` (wrapper only)
- `module.front_door` (wrapper only)

### Supporting Services Modules
- `avm-res-keyvault-vault` (Key Vault)
- `avm-res-storage-storageaccount` (Storage)
- `avm-res-containerregistry-registry` (ACR)
- `avm-res-network-privatednszone` (Private DNS)

### Container Apps Environment Module
- `avm-res-app-managedenvironment` (Container Apps Environment)
- `avm-res-insights-component` (Application Insights)
- `avm-res-network-privatednszone` (Private DNS)

### Application Gateway Module
- `avm-res-network-applicationgateway` (Application Gateway)
- `avm-res-network-publicipaddress` (Public IP)

### Spoke Module
- `avm-res-network-virtualnetwork` (Virtual Network)
- `avm-res-operationalinsights-workspace` (Log Analytics)

---

## Example Code Resources (DO NOT MIGRATE)

Example files under `examples/` directory are for demonstration purposes and use AzureRM for simplicity. These include:
- Resource groups in all examples
- Hub VNets in `complex-network-appliance`, `hub-spoke-linux-vm`, `bastion-zone-redundant`
- Azure Firewall resources in `complex-network-appliance`
- Route tables and associations in `complex-network-appliance`

**Rationale**: Example code demonstrates module usage and doesn't need to follow the same standards as the module itself.

---

## Migration Strategy

### Phase 1: Preparation (0.5 day)
1. ✅ **Inventory Complete** - This document
2. Query AzAPI schemas for all required resource types
3. Document property mappings from AzureRM to AzAPI
4. Set up testing environment

### Phase 2: Sequential Module Migration (3-5 days)

**Day 1: Key Vault & Application Gateway** (Low-risk warm-up)
- **Morning**: Key Vault data source migration (2-4 hours)
  - Replace `data.azurerm_client_config` 
  - Test with Key Vault module
  
- **Afternoon**: Application Gateway WAF migration (4-6 hours)
  - Replace `azurerm_web_application_firewall_policy`
  - Replace `data.azurerm_public_ip`
  - Test App Gateway deployment
  - Run AVM pre-commit

**Day 2-3: Front Door Core** (Critical path)
- Replace `azurerm_cdn_frontdoor_profile`
- Replace `azurerm_cdn_frontdoor_endpoint`
- Replace `azurerm_cdn_frontdoor_origin_group`
- Replace `azurerm_cdn_frontdoor_origin` (includes private link)
- Test basic Front Door creation with private link
- Validate private endpoint approval

**Day 4: Front Door Routing & Security**
- Replace `azurerm_cdn_frontdoor_route` (including dynamic cache)
- Replace `azurerm_cdn_frontdoor_firewall_policy`
- Replace `azurerm_cdn_frontdoor_security_policy`
- Replace `azurerm_monitor_diagnostic_setting`
- Test WAF and caching behavior

**Day 5: Final Validation**
- End-to-end testing with all examples
- Run AVM pre-commit and pr-check
- Update documentation
- Final commit and push

---

## Technical Migration Details

### Front Door: AzureRM → AzAPI Mapping

#### Profile Resource
```terraform
# BEFORE (AzureRM)
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = 120
  tags                     = var.tags
}

# AFTER (AzAPI)
resource "azapi_resource" "frontdoor_profile" {
  type      = "Microsoft.Cdn/profiles@2024-02-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = "Global"
  
  body = {
    sku = {
      name = var.sku_name
    }
    properties = {
      originResponseTimeoutSeconds = 120
    }
  }
  
  tags = var.tags
  
  schema_validation_enabled = true
}
```

#### Origin with Private Link (Critical)
```terraform
# BEFORE (AzureRM)
resource "azurerm_cdn_frontdoor_origin" "this" {
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  certificate_name_check_enabled = false
  host_name                      = var.backend_fqdn
  name                           = "${var.name}-origin"
  enabled                        = true
  http_port                      = 80
  https_port                     = var.backend_port
  origin_host_header             = var.backend_fqdn
  priority                       = 1
  weight                         = 1000

  private_link {
    location               = var.location
    private_link_target_id = var.container_apps_environment_id
    request_message        = "Front Door Private Link Request for Container Apps"
    target_type            = "managedEnvironments"
  }
}

# AFTER (AzAPI)
resource "azapi_resource" "frontdoor_origin" {
  type      = "Microsoft.Cdn/profiles/originGroups/origins@2024-02-01"
  name      = "${var.name}-origin"
  parent_id = azapi_resource.frontdoor_origin_group.id
  
  body = {
    properties = {
      hostName                    = var.backend_fqdn
      httpPort                    = 80
      httpsPort                   = var.backend_port
      originHostHeader            = var.backend_fqdn
      priority                    = 1
      weight                      = 1000
      enabledState                = "Enabled"
      enforceCertificateNameCheck = false
      
      sharedPrivateLinkResource = {
        privateLink = {
          id = var.container_apps_environment_id
        }
        privateLinkLocation = var.location
        requestMessage      = "Front Door Private Link Request for Container Apps"
        groupId             = "managedEnvironments"
      }
    }
  }
  
  depends_on = [
    azapi_resource.frontdoor_origin_group
  ]
}
```

#### Route with Dynamic Cache
```terraform
# BEFORE (AzureRM)
resource "azurerm_cdn_frontdoor_route" "this" {
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]
  name                          = "${var.name}-route"
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]
  enabled                       = true
  forwarding_protocol           = var.forwarding_protocol
  https_redirect_enabled        = true

  dynamic "cache" {
    for_each = var.caching_enabled ? [1] : []
    content {
      compression_enabled           = true
      content_types_to_compress     = [...]
      query_string_caching_behavior = "IgnoreQueryString"
      query_strings                 = []
    }
  }
}

# AFTER (AzAPI)
resource "azapi_resource" "frontdoor_route" {
  type      = "Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01"
  name      = "${var.name}-route"
  parent_id = azapi_resource.frontdoor_endpoint.id
  
  body = {
    properties = {
      originGroup = {
        id = azapi_resource.frontdoor_origin_group.id
      }
      originPath              = null
      patternsToMatch         = ["/*"]
      supportedProtocols      = ["Http", "Https"]
      forwardingProtocol      = var.forwarding_protocol
      linkToDefaultDomain     = "Enabled"
      httpsRedirect           = "Enabled"
      enabledState            = "Enabled"
      
      cacheConfiguration = var.caching_enabled ? {
        compressionSettings = {
          contentTypesToCompress = [
            "application/eot",
            "application/font",
            # ... full list
          ]
          isCompressionEnabled = true
        }
        queryStringCachingBehavior = "IgnoreQueryString"
        queryParameters            = null
      } : null
    }
  }
  
  depends_on = [
    azapi_resource.frontdoor_endpoint,
    azapi_resource.frontdoor_origin_group,
    azapi_resource.frontdoor_origin
  ]
}
```

### Application Gateway: WAF Policy Migration

```terraform
# BEFORE (AzureRM)
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

# AFTER (AzAPI)
resource "azapi_resource" "waf_policy" {
  type      = "Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01"
  name      = "${var.name}Policy001"
  parent_id = var.resource_group_id
  location  = var.location
  
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
        state                 = "Enabled"
        mode                  = "Prevention"
        fileUploadLimitInMb   = 10
        requestBodyCheck      = true
        maxRequestBodySizeInKb = 128
      }
    }
  }
  
  tags = var.tags
  
  schema_validation_enabled = true
}
```

### Key Vault: Client Config Alternative

```terraform
# BEFORE (AzureRM)
data "azurerm_client_config" "current" {}

locals {
  principal_type = (
    trimspace(data.azurerm_client_config.current.client_id) == "" ||
    lower(trimspace(data.azurerm_client_config.current.client_id)) == local.azure_cli_client_id
    ? "User"
    : "ServicePrincipal"
  )
}

# OPTION 1: AzAPI (if available)
data "azapi_client_config" "current" {}

# OPTION 2: AzureAD Provider
data "azuread_client_config" "current" {}

# OPTION 3: Pass as Variables (Most Reliable)
variable "tenant_id" {
  type        = string
  description = "Azure tenant ID for Key Vault access"
}

variable "principal_object_id" {
  type        = string
  description = "Object ID of the principal deploying the module"
}

variable "principal_type" {
  type        = string
  default     = "ServicePrincipal"
  description = "Type of principal: User or ServicePrincipal"
}
```

---

## Testing Strategy

### Unit Testing
- Each migrated resource must pass schema validation
- Test all conditional logic (WAF enabled/disabled, caching enabled/disabled)
- Validate all computed properties and outputs

### Integration Testing
- Deploy full stack with Front Door + Container Apps
- Verify private endpoint approval still works
- Test traffic flow through Front Door to Container Apps
- Validate WAF rules and blocking behavior
- Test diagnostic settings and log collection

### Regression Testing
- All existing examples must deploy successfully
- No changes to outputs or module interface (breaking changes documented)
- All pre-commit and pr-check validations pass

### Performance Testing
- Compare deployment times before/after migration
- Monitor Terraform plan/apply performance
- Validate no degradation in Azure resource provisioning

---

## Risk Mitigation

### High Risks

1. **Private Link Configuration Changes**
   - **Risk**: AzAPI schema differences break private endpoint connectivity
   - **Mitigation**: 
     - Query exact schema before migration
     - Test in isolated environment first
     - Keep null_resource approval mechanism as fallback

2. **Cache Configuration Complexity**
   - **Risk**: Dynamic cache block translation loses functionality
   - **Mitigation**:
     - Map all AzureRM cache properties to AzAPI equivalents
     - Test with caching enabled/disabled scenarios
     - Validate content-type compression lists

3. **Breaking Changes for Users**
   - **Risk**: Resource IDs change, forcing replacement
   - **Mitigation**:
     - Document all breaking changes
     - Provide migration guide for existing deployments
     - Consider state migration scripts if needed

### Medium Risks

1. **WAF Policy Differences**
   - **Risk**: Managed rule set schema variations
   - **Mitigation**: Test all OWASP and Bot Protection rules

2. **Diagnostic Settings**
   - **Risk**: Log categories may differ between providers
   - **Mitigation**: Compare available log categories before/after

3. **Telemetry Deployment**
   - **Risk**: ARM template deployment may need adjustment
   - **Mitigation**: Keep existing azurerm_resource_group_template_deployment

### Low Risks

1. **Data Source Migration**
   - **Risk**: Minimal - data sources rarely cause issues
   - **Mitigation**: Simple testing validates functionality

2. **Tag Propagation**
   - **Risk**: Tags may not propagate identically
   - **Mitigation**: Verify tags on all child resources

---

## Dependencies & Prerequisites

### Required Tools & Versions
- Terraform >= 1.6.0
- AzAPI Provider >= 2.0.0 (already in use)
- Azure CLI >= 2.50.0 (for testing)
- jq (for schema queries)

### API Version Research Required
Query the following API versions for schema documentation:
```bash
# Front Door
az rest --method get --url "https://management.azure.com/providers/Microsoft.Cdn?api-version=2024-02-01"

# Application Gateway WAF
az rest --method get --url "https://management.azure.com/providers/Microsoft.Network?api-version=2024-01-01"

# Diagnostic Settings
az rest --method get --url "https://management.azure.com/providers/Microsoft.Insights?api-version=2021-05-01-preview"
```

### Azure Permissions Required
- Contributor access to test resource groups
- Permission to create Front Door Premium resources
- Permission to approve private endpoint connections
- Read access to diagnostic settings

---

## Success Criteria

### Must-Have (Blocking v1.0 Release)
- ✅ All direct AzureRM resources replaced with AzAPI
- ✅ All AVM pre-commit checks pass
- ✅ All AVM pr-check validations pass
- ✅ Front Door private link connectivity working
- ✅ All examples deploy successfully
- ✅ Module interface unchanged (variables/outputs)
- ✅ Schema validation enabled on all AzAPI resources

### Should-Have (High Priority)
- ✅ Performance parity with AzureRM provider
- ✅ Updated README with AzAPI references
- ✅ Clean terraform validate and plan

### Nice-to-Have (Low Priority)
- Improved error messages using AzAPI schema validation
- Code comments explaining AzAPI-specific patterns

---

## Post-Migration Checklist

### Code Quality
- [ ] All AzureRM resources replaced with `azapi_resource`
- [ ] Schema validation enabled: `schema_validation_enabled = true`
- [ ] Comments updated to reference AzAPI patterns
- [ ] Resource naming consistent

### Testing
- [ ] All examples deploy successfully
- [ ] Private link connectivity verified
- [ ] WAF rules tested and blocking correctly
- [ ] Diagnostic logs flowing to Log Analytics
- [ ] null_resource approval still works

### Validation
- [ ] `terraform fmt -recursive` runs clean
- [ ] `terraform validate` passes
- [ ] `./avm pre-commit` passes
- [ ] `./avm pr-check` passes
- [ ] No deprecated warnings
- [ ] All outputs unchanged

### Documentation
- [ ] README updated with AzAPI provider info
- [ ] API version requirements documented
- [ ] Comments explain AzAPI-specific patterns

### Release Prep
- [ ] Ready for v1.0.0 release
- [ ] AVM compliance achieved

---

## Rollback Plan

Since there are no existing users, rollback is straightforward:

1. **Git Revert**
   - Simply revert the commit(s) if issues arise
   - No state migration concerns
   - No user impact

2. **Incremental Approach**
   - Commit each module migration separately
   - Easy to identify which change caused issues
   - Can revert specific modules if needed

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Preparation | 0.5 day | None |
| Key Vault + App Gateway | 1 day | Preparation complete |
| Front Door Core | 1.5 days | App Gateway complete |
| Front Door Routing & Security | 1 day | Core complete |
| Final Testing & Validation | 1 day | All migrations complete |

**Total Estimated Duration**: 5 working days

**Critical Path**: Front Door module (2.5 days)

**Simplified by**: No state migration, no breaking changes communication, no user impact analysis

---

## Open Questions

1. **AzAPI Client Config**: Does `azapi_client_config` data source exist, or should we use azuread provider or variables?
2. **API Versions**: What's the latest stable API version for Front Door? (2024-02-01 assumed)
3. **Telemetry**: Should telemetry ARM template remain as azurerm_resource_group_template_deployment?
4. **Commit Strategy**: One big commit or separate commits per module?

---

## Approval & Sign-Off

**Document prepared by**: GitHub Copilot Agent  
**Date**: 2025-10-14  
**Version**: 1.0  
**Status**: DRAFT - Awaiting review

**Next Steps**:
1. Review and approve migration plan
2. Resolve open questions
3. Schedule migration execution
4. Begin Phase 1: Preparation

---

## Appendix A: API Version Matrix

| Resource Type | API Version | Status | Notes |
|--------------|-------------|--------|-------|
| Microsoft.Cdn/profiles | 2024-02-01 | Latest GA | Front Door profiles |
| Microsoft.Cdn/profiles/afdEndpoints | 2024-02-01 | Latest GA | Front Door endpoints |
| Microsoft.Cdn/profiles/originGroups | 2024-02-01 | Latest GA | Origin groups |
| Microsoft.Cdn/profiles/originGroups/origins | 2024-02-01 | Latest GA | Origins with private link |
| Microsoft.Cdn/profiles/afdEndpoints/routes | 2024-02-01 | Latest GA | Routes |
| Microsoft.Cdn/profiles/securityPolicies | 2024-02-01 | Latest GA | Security policies |
| Microsoft.Network/FrontDoorWebApplicationFirewallPolicies | 2024-02-01 | Latest GA | WAF policies |
| Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies | 2024-01-01 | Latest GA | App Gateway WAF |
| Microsoft.Insights/diagnosticSettings | 2021-05-01-preview | Latest | Diagnostic settings |
| Microsoft.Network/publicIPAddresses | 2024-01-01 | Latest GA | Public IP data source |

## Appendix B: AzAPI Provider Benefits

**Why AzAPI for AVM v1.0?**

1. **Day-0 Support**: New Azure features available immediately via API versions
2. **Microsoft Ownership**: Direct support from Azure team
3. **Consistency**: Same API contracts as Azure Portal, CLI, and PowerShell
4. **Flexibility**: Access to preview features without waiting for AzureRM releases
5. **Reduced Lag**: No delay between Azure feature release and Terraform support
6. **Better Error Messages**: Direct API errors provide clearer diagnostics
7. **Schema Validation**: Built-in validation against Azure API schemas

**Trade-offs:**
- More verbose syntax compared to AzureRM
- Less community documentation (newer provider)
- Requires understanding of Azure REST API structure
- Schema changes with API version updates

---

## Appendix C: Reference Links

- [AzAPI Provider Documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Azure Verified Modules Specifications](https://azure.github.io/Azure-Verified-Modules/)
- [Front Door REST API Reference](https://learn.microsoft.com/en-us/rest/api/frontdoor/)
- [Application Gateway REST API Reference](https://learn.microsoft.com/en-us/rest/api/application-gateway/)
- [AzAPI Examples Repository](https://github.com/Azure/terraform-provider-azapi/tree/main/examples)

---

*End of Migration Plan*
