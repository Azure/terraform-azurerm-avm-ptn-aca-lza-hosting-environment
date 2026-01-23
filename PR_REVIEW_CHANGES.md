# PR #12 Review Comments - Resolution Plan

This document outlines the review comments from PR #12 and the proposed changes to resolve them.

**Reviewer:** @jaredfholgate  
**Review Status:** Changes Requested  
**Summary:** "Quick first pass review. Looking really good, just some improvements to make to ensure they meet and can be tested against AVM standards."

---

## Changes by Size/Complexity

| Priority | Size | Category | Changes |
|----------|------|----------|---------|
| 🟢 | **Small** | Quick Fixes | #1, #3, #5, #13, #16, #17 |
| 🟡 | **Medium** | Moderate Refactoring | #2, #4, #8, #10, #14, #15 |
| 🔴 | **Large** | Breaking Changes (Renames) | #6, #7, #9, #11, #12 |

### 🟢 Small Changes (Quick Wins)
These can be done quickly with minimal risk:

| # | Description | Files Affected | Est. Time |
|---|-------------|----------------|-----------|
| 1 | Move validation to variable block | `main.tf`, `variables.tf` | 10 min |
| 3 | Use AzAPI `parse_resource_id` function | `main.tf` | 5 min |
| 5 | Document/parameterize Front Door SKU | `main.tf` or `variables.tf` | 10 min |
| 13 | Fix Application Insights output | `outputs.tf` | 5 min |
| 16 | Move outputs to `outputs.tf` | `modules/spoke/log_analytics/` | 10 min |
| 17 | Remove VS Code workspace file | Root directory | 2 min |

### 🟡 Medium Changes (Moderate Effort)
These require some refactoring but aren't breaking:

| # | Description | Files Affected | Est. Time |
|---|-------------|----------------|-----------|
| 2 | Use `random_string` provider | `main.tf`, `terraform.tf` | 20 min |
| 4 | Remove explicit `depends_on` blocks | `main.tf` | 15 min |
| 8 | Clarify DDoS protection description | `variables.tf` | 10 min |
| 10 | Document sensitive data state storage | `variables.tf` | 10 min |
| 14 | Flatten nested submodules | `modules/` structure | 45 min |
| 15 | Convert map keys to snake_case | `modules/spoke/main.tf` | 30 min |

### 🔴 Large Changes (Breaking - Requires Migration Guide)
These are breaking changes that affect all users:

| # | Description | Files Affected | Est. Time |
|---|-------------|----------------|-----------|
| 6 | Rename booleans to `*_enabled` | All `.tf` files, all examples | 2 hrs |
| 7 | Add `nullable = false` to variables | `variables.tf` | 30 min |
| 9 | Change camelCase to snake_case values | `variables.tf`, `main.tf`, examples | 1 hr |
| 11 | Rename `vm_size` → `virtual_machine_sku` | `variables.tf`, modules, examples | 30 min |
| 12 | Rename `vm_*` → `virtual_machine_*` | `variables.tf`, modules, examples | 1.5 hrs |

---

## Recommended Implementation Order

### Phase 1: Quick Wins (Day 1)
1. Remove VS Code workspace file (#17)
2. Fix Application Insights output (#13)
3. Move outputs to outputs.tf (#16)
4. Use AzAPI parse_resource_id (#3)
5. Move validation to variable block (#1)
6. Document Front Door SKU (#5)

### Phase 2: Moderate Refactoring (Day 1-2)
7. Remove explicit depends_on (#4)
8. Use random_string provider (#2)
9. Update variable descriptions (#8, #10)
10. Flatten nested submodules (#14)
11. Convert map keys to snake_case (#15)

### Phase 3: Breaking Changes (Day 2-3)
12. Add nullable = false (#7)
13. Change camelCase values to snake_case (#9)
14. Rename vm_* to virtual_machine_* (#11, #12)
15. Rename booleans to *_enabled (#6)
16. Update all examples
17. Run AVM validation

---

## Detailed Changes

## Table of Contents

1. [Small Changes](#small-changes)
2. [Medium Changes](#medium-changes)
3. [Large Changes](#large-changes)

---

## Small Changes

### 1. Move Validation to Variable Validation Block (Line 6)

**Comment:** "Did you know you can refer to other variables in variable validation conditions? Can this be moved there instead?"

**Current Code:**
```hcl
resource "null_resource" "resource_group_validation" {
  lifecycle {
    precondition {
      condition     = !(var.created_resource_group_name != null && var.existing_resource_group_id != null)
      error_message = "Cannot specify both created_resource_group_name (for new RG) and existing_resource_group_id (for existing RG). Please provide only one, or leave both null for auto-generation."
    }
  }
}
```

**Proposed Change:**
Remove the `null_resource` validation block and add the validation condition to the `created_resource_group_name` variable in `variables.tf`:

```hcl
variable "created_resource_group_name" {
  type        = string
  default     = null
  description = "Optional. Name to use when creating a new resource group. Leave null for auto-generation."

  validation {
    condition     = !(var.created_resource_group_name != null && var.existing_resource_group_id != null)
    error_message = "Cannot specify both created_resource_group_name (for new RG) and existing_resource_group_id (for existing RG). Please provide only one, or leave both null for auto-generation."
  }
}
```

---

### 2. Use Random Provider Instead of Deterministic Uniqueness (Line 18)

**Comment:** "Why not use the random provider for this? It will then get stored in state and doesn't need to be deterministic."

**Current Code:**
```hcl
locals {
  naming_unique_id = substr(lower(replace(base64encode(sha256(local.naming_unique_seed)), "=", "")), 0, 13)
  naming_unique_seed = join("|", [
    data.azapi_client_config.naming.subscription_id,
    local.safe_location,
    var.environment,
    var.workload_name,
  ])
}
```

**Proposed Change:**
Replace the deterministic hash with the `random_string` resource:

```hcl
resource "random_string" "naming_unique_id" {
  length  = 13
  lower   = true
  upper   = false
  special = false
  numeric = true
}

locals {
  naming_unique_id = random_string.naming_unique_id.result
}
```

---

### 3. Use AzAPI Provider Function for Resource ID Parsing (Line 28)

**Comment:** "azapi has provider defined functions for this: https://registry.terraform.io/providers/Azure/azapi/latest/docs/functions/parse_resource_id"

**Current Code:**
```hcl
resource_group_name = local.use_existing_resource_group ? regex("/resourceGroups/([^/]+)", var.existing_resource_group_id)[0] : ...
```

**Proposed Change:**
Use the `azapi_parse_resource_id` provider function instead of regex:

```hcl
resource_group_name = local.use_existing_resource_group ? provider::azapi::parse_resource_id(var.existing_resource_group_id).resource_group_name : ...
```

---

### 4. Remove Explicit Dependencies on Modules (Lines 89, 110, 140, 158)

**Comment:** "Using explicit dependencies on modules can cause idempotency issues, please avoid and always use implicit dependencies."

**Current Code (multiple instances):**
```hcl
module "spoke" {
  ...
  depends_on = [module.spoke_resource_group]
}

module "supporting_services" {
  ...
  depends_on = [module.spoke_resource_group]
}

module "container_apps_environment" {
  ...
  depends_on = [module.spoke_resource_group]
}

module "sample_application" {
  ...
  depends_on = [module.spoke_resource_group]
}
```

**Proposed Change:**
Remove all `depends_on` blocks and ensure dependencies are implicit through variable references. The `local.resource_group_id` and `local.resource_group_name` already create implicit dependencies on `module.spoke_resource_group`.

---

### 5. Hard-coded SKU Value (Line 202)

**Comment:** "Should this be hard-coded?"

**Current Code:**
```hcl
sku_name = "Premium_AzureFrontDoor" # Required for Private Link
```

**Proposed Change:**
Add a comment explaining why this is intentionally hard-coded OR create a variable:

Option A (Keep hard-coded with better documentation):
```hcl
# Premium SKU is required for Private Link support with internal Container Apps Environment
# See: https://learn.microsoft.com/azure/frontdoor/standard-premium/concept-private-link
sku_name = "Premium_AzureFrontDoor"
```

Option B (Make configurable but with validation):
```hcl
variable "front_door_sku_name" {
  type        = string
  default     = "Premium_AzureFrontDoor"
  description = "The SKU for Azure Front Door. Premium_AzureFrontDoor is required for Private Link support."
  nullable    = false

  validation {
    condition     = var.front_door_sku_name == "Premium_AzureFrontDoor"
    error_message = "Premium_AzureFrontDoor SKU is required for Private Link support with internal Container Apps Environment."
  }
}
```

---

## variables.tf Changes

### 6. Boolean Variable Naming Convention (Lines 6, 182)

**Comment:** "Boolean variables should follow the naming convention `<whatever>_enabled` with `_enabled` as the postfix."

**Variables to Rename:**

| Current Name | Proposed Name |
|-------------|---------------|
| `enable_application_insights` | `application_insights_enabled` |
| `enable_dapr_instrumentation` | `dapr_instrumentation_enabled` |
| `enable_bastion_access` | `bastion_access_enabled` |
| `enable_ddos_protection` | `ddos_protection_enabled` |
| `enable_egress_lockdown` | `egress_lockdown_enabled` |
| `enable_hub_peering` | `hub_peering_enabled` |
| `enable_telemetry` | `telemetry_enabled` |
| `deploy_sample_application` | `sample_application_enabled` |
| `deploy_zone_redundant_resources` | `zone_redundant_resources_enabled` |
| `front_door_enable_waf` | `front_door_waf_enabled` |
| `generate_ssh_key_for_vm` | `virtual_machine_ssh_key_generation_enabled` |

**Note:** This is a breaking change and will require updates throughout the module and all examples.

---

### 7. Add `nullable = false` to Variables (Line 7)

**Comment:** "Set `nullable = false` if you don't want people to supply null. This applies to all the other variables here."

**Variables to Update:**
Add `nullable = false` to all variables that have non-null defaults and should not accept null values:

- `enable_application_insights` (after rename)
- `enable_dapr_instrumentation` (after rename)
- `deploy_sample_application` (after rename)
- `deploy_zone_redundant_resources` (after rename)
- `enable_bastion_access`
- `enable_ddos_protection`
- `enable_egress_lockdown`
- `enable_hub_peering`
- `enable_telemetry`
- `environment`
- `expose_container_apps_with`
- `front_door_enable_waf`
- `generate_ssh_key_for_vm`
- `log_analytics_workspace_replication_enabled`
- `route_spoke_traffic_internally`
- `storage_account_type`
- `use_existing_resource_group`
- `vm_authentication_type`
- `vm_jumpbox_os_type`
- `workload_name`

---

### 8. Clarify DDoS Protection Description (Line 69)

**Comment:** "Enable DDOS protection in what? All the public IPs? Does this module integrate with the ALZ Platform Landing Zone and leverage the plan there? Is this for per IP DDOS protection?"

**Current Code:**
```hcl
variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus. Default is \"false\"."
}
```

**Proposed Change:**
```hcl
variable "ddos_protection_enabled" {
  type        = bool
  default     = false
  description = "Optional. Enable DDoS protection on the Application Gateway public IP address. When enabled, the public IP will use DDoS IP Protection mode. For integration with Azure Landing Zone DDoS Protection Plan, use the dedicated ALZ module. See https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus for more information. Default is false."
  nullable    = false
}
```

---

### 9. Change camelCase Keys to snake_case (Line 129)

**Comment:** "Why are these camel case? Can they be snake case, which is standard for Terraform?"

**Current Code (in `expose_container_apps_with` validation):**
```hcl
validation {
  condition     = contains(["applicationGateway", "frontDoor", "none"], var.expose_container_apps_with)
  error_message = "expose_container_apps_with must be one of: applicationGateway, frontDoor, none."
}
```

**Proposed Change:**
```hcl
variable "expose_container_apps_with" {
  type        = string
  default     = "application_gateway"
  description = "Optional. Specify the way container apps is going to be exposed. Options are application_gateway, front_door, or none. Default is \"application_gateway\"."
  nullable    = false

  validation {
    condition     = contains(["application_gateway", "front_door", "none"], var.expose_container_apps_with)
    error_message = "expose_container_apps_with must be one of: application_gateway, front_door, none."
  }
}
```

**Note:** This requires updates throughout the module where these values are compared.

---

### 10. Sensitive Data in State (Line 217)

**Comment:** "Are we doing anything to prevent this being stored in state?"

**Current Code:**
```hcl
variable "vm_admin_password" {
  type        = string
  default     = null
  description = "Optional. The password to use for the virtual machine. Required when vm_jumpbox_os_type is not 'none'. Default is null."
  sensitive   = true
}
```

**Proposed Change:**
The `sensitive = true` attribute already marks the variable as sensitive, which prevents it from being displayed in logs and plan output. However, the value will still be stored in state. Add documentation to clarify this:

```hcl
variable "virtual_machine_admin_password" {
  type        = string
  default     = null
  description = <<-EOT
    Optional. The password to use for the virtual machine. Required when virtual_machine_jumpbox_os_type is not 'none'. 
    Default is null.
    
    NOTE: This value is marked as sensitive and will not be displayed in logs or plan output.
    However, it will be stored in Terraform state. Ensure your state backend is properly secured.
    Consider using Azure Key Vault integration for production deployments.
  EOT
  sensitive   = true
}
```

---

### 11. Rename `vm_size` to `virtual_machine_sku` (Line 275)

**Comment:** "Should this be called virtual_machine_sku?"

**Current Code:**
```hcl
variable "vm_size" {
  type        = string
  default     = null
  description = "Optional. The size of the virtual machine to create..."
}
```

**Proposed Change:**
```hcl
variable "virtual_machine_sku" {
  type        = string
  default     = null
  description = "Optional. The SKU (size) of the virtual machine to create. Required when virtual_machine_jumpbox_os_type is not 'none'. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information. Default is null."
}
```

---

### 12. Don't Use Initials in Variable Names (Line 217)

**Comment:** "Don't use initials in variable or local names. `vm` should be `virtual_machine`, etc..."

**Variables to Rename:**

| Current Name | Proposed Name |
|-------------|---------------|
| `vm_admin_password` | `virtual_machine_admin_password` |
| `vm_authentication_type` | `virtual_machine_authentication_type` |
| `vm_jumpbox_os_type` | `virtual_machine_jumpbox_os_type` |
| `vm_jumpbox_subnet_address_prefix` | `virtual_machine_jumpbox_subnet_address_prefix` |
| `vm_linux_ssh_authorized_key` | `virtual_machine_linux_ssh_authorized_key` |
| `vm_size` | `virtual_machine_sku` |
| `vm_zone` | `virtual_machine_zone` |

---

## outputs.tf Changes

### 13. Application Insights Output Incorrect (Line 13)

**Comment:** "This doesn't look right?"

**Current Code:**
```hcl
output "application_insights_id" {
  description = "The resource ID of Application Insights (when enabled)."
  value       = module.container_apps_environment.managed_environment_id
}
```

**Proposed Change:**
The output incorrectly references the managed environment ID instead of the Application Insights ID:

```hcl
output "application_insights_id" {
  description = "The resource ID of Application Insights (when enabled)."
  value       = module.container_apps_environment.application_insights_id
}
```

**Note:** This requires the `container_apps_environment` module to expose the `application_insights_id` output.

---

## Module Structure Changes

### 14. Avoid Nested Submodules (modules/supporting_services/container_registry/main.tf)

**Comment:** "Please avoid nesting submodules like this. Our tooling won't handle this and I don't think Terraform registry will handle it properly. There is not issue with using relative module path, like `source = \"../whatever\"`."

**Current Structure:**
```
modules/
  supporting_services/
    container_registry/
      main.tf  <- This calls nested modules
    key_vault/
    storage/
```

**Proposed Change:**
Flatten the module structure. Move submodules to the top-level `modules/` directory or inline their functionality:

Option A (Flatten):
```
modules/
  container_registry/
  key_vault/
  storage/
  supporting_services/
```

Option B (Inline):
Inline the container_registry, key_vault, and storage modules directly into the `supporting_services` module.

---

### 15. Use snake_case for Map Keys (modules/spoke/main.tf Line 53)

**Comment:** "Please ensure snake case is used throughout. These keys should all be lower case."

**Current Code:**
```hcl
security_rules = {
  Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP = {
    name = "Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP"
    ...
  }
}
```

**Proposed Change:**
```hcl
security_rules = {
  allow_internal_aks_connection_between_nodes_and_control_plane_udp = {
    name = "allow-internal-aks-connection-between-nodes-and-control-plane-udp"
    ...
  }
}
```

---

### 16. Move Outputs to outputs.tf (modules/spoke/log_analytics/main.tf Line 45)

**Comment:** "Put outputs in outputs.tf"

**Current Code (in main.tf):**
```hcl
output "id" {
  value       = azapi_resource.workspace.id
  description = "Resource ID of the Log Analytics Workspace"
}

output "name" {
  value       = azapi_resource.workspace.name
  description = "Name of the Log Analytics Workspace"
}

output "workspace_id" {
  value       = try(azapi_resource.workspace.output.properties.customerId, null)
  description = "Workspace (customer) ID"
}
```

**Proposed Change:**
Move these outputs to `modules/spoke/log_analytics/outputs.tf`.

---

## File Cleanup

### 17. Remove VS Code Workspace File

**Comment:** "What is this file?"

**File:** `terraform-azurerm-avm-ptn-aca-lza-hosting-environment.code-workspace`

**Current Content:**
```jsonc
{
  "folders": [
    { "path": "." },
    { "path": "../aca-lz-bicep" }
  ],
  "settings": {}
}
```

**Proposed Change:**
This is a VS Code workspace file that references a local path outside the repository. It should be:
1. **Removed from the repository** - VS Code workspace files are typically developer-specific and should not be committed
2. **Added to `.gitignore`** - Add `*.code-workspace` to prevent future commits

---

## Summary of Breaking Changes

The following changes are **breaking changes** that will affect existing users:

1. **Variable renames** (boolean convention, vm → virtual_machine)
2. **Value changes** for `expose_container_apps_with` (camelCase → snake_case)

### Migration Guide for Users

Users upgrading to the new version will need to update their Terraform configurations:

```hcl
# Before
module "aca_lza" {
  ...
  enable_application_insights = true
  enable_hub_peering          = true
  vm_size                     = "Standard_D2s_v3"
  expose_container_apps_with  = "applicationGateway"
}

# After
module "aca_lza" {
  ...
  application_insights_enabled = true
  hub_peering_enabled          = true
  virtual_machine_sku          = "Standard_D2s_v3"
  expose_container_apps_with   = "application_gateway"
}
```

---

## Implementation Checklist

### 🟢 Phase 1: Small Changes (Quick Wins)
- [ ] #17 - Remove VS Code workspace file, add to `.gitignore`
- [ ] #13 - Fix Application Insights output reference
- [ ] #16 - Move outputs to `outputs.tf` in log_analytics module
- [ ] #3 - Use `azapi::parse_resource_id` instead of regex
- [ ] #1 - Move validation from `null_resource` to variable validation
- [ ] #5 - Document Front Door SKU requirement

### 🟡 Phase 2: Medium Changes (Moderate Effort)
- [ ] #4 - Remove all `depends_on` blocks from modules
- [ ] #2 - Replace deterministic hash with `random_string` resource
- [ ] #8 - Clarify DDoS protection description
- [ ] #10 - Document sensitive data state storage
- [ ] #14 - Flatten nested submodules structure
- [ ] #15 - Convert map keys to snake_case

### 🔴 Phase 3: Large Changes (Breaking - Update Examples)
- [ ] #7 - Add `nullable = false` to appropriate variables
- [ ] #9 - Change camelCase values to snake_case (`applicationGateway` → `application_gateway`)
- [ ] #11 - Rename `vm_size` to `virtual_machine_sku`
- [ ] #12 - Rename all `vm_*` variables to `virtual_machine_*`
- [ ] #6 - Rename all boolean variables to `*_enabled` convention
- [ ] Update all examples with new variable names
- [ ] Run `PORCH_NO_TUI=1 ./avm pre-commit`
- [ ] Run `PORCH_NO_TUI=1 ./avm pr-check`

