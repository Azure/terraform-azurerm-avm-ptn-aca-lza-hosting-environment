# Idempotency Fixes for AVM Compliance

## Summary

This document describes the idempotency issues identified during PR checks and the fixes applied to resolve them.

## Issues Identified

### 1. Diagnostic Settings Missing `log_analytics_destination_type`

**Problem**: Diagnostic settings for ACR and Storage Account were missing the `log_analytics_destination_type` parameter, causing Terraform to want to update them on subsequent plans.

**Impact**: Terraform plan after apply showed:
```
+ log_analytics_destination_type = "Dedicated"
```

**Fix**: Added `log_analytics_destination_type = "Dedicated"` to all diagnostic settings configurations:
- `modules/supporting_services/container_registry/main.tf`
- `modules/supporting_services/storage/main.tf`
- `modules/spoke/main.tf` (all 4 NSG modules)

**Status**: ✅ FIXED

### 2. Storage Account Diagnostic Settings Metric Format

**Problem**: Storage account diagnostic settings were using individual metric categories instead of the consolidated "AllMetrics" format.

**Impact**: Terraform plan showed:
```diff
- enabled_metric {
    - category = "Capacity" -> null
  }
- enabled_metric {
    - category = "Transaction" -> null
  }
+ enabled_metric {
    + category = "AllMetrics"
  }
```

**Fix**: Updated storage account diagnostic settings to use `metric_categories = ["AllMetrics"]`

**Status**: ✅ FIXED (This is the correct AVM format)

### 3. NSG Security Rules Added by Azure Platform

**Problem**: Azure Container Apps automatically adds required NSG security rules after the Container Apps Environment is created. These rules appear as drift in Terraform plans.

**Azure-Added Rules**:
- `Allow_Outbound_443`
- `Allow_Azure_Monitor`
- `Allow_Container_Apps_control_plane`
- `Allow_NTP_Server`
- `Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP`
- `Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_TCP`
- `deny-hop-outbound`

**Impact**: Idempotency checks show NSG updates with new security rules.

**Root Cause**: Azure Container Apps managed environment requires specific network rules and automatically provisions them. This is documented Azure platform behavior.

**Status**: ⚠️ EXPECTED BEHAVIOR - This is by design. Azure manages these rules as part of the Container Apps platform.

**Recommendation**: This is not a bug. The rules are necessary for Container Apps to function and are managed by the Azure platform. Future deployments starting from our fixed code will have these changes already applied after the first run.

### 4. Private DNS Zone Computed Values

**Problem**: Private DNS zones show changes to read-only computed properties:
- `numberOfRecordSets`
- `numberOfVirtualNetworkLinks`
- Container Registry `data_endpoint_host_names`

**Impact**: These values change from their initial state (e.g., `0 -> 1`) after resources are linked.

**Root Cause**: These are read-only properties populated by Azure after resource creation and linking.

**Status**: ⚠️ EXPECTED BEHAVIOR - These are computed values managed by Azure.

## Testing Impact

When running the idempotency check against an existing deployment:
1. First apply will create resources
2. Azure platform will automatically add NSG rules and populate computed values
3. Second plan (idempotency check) will show these platform-managed changes

When running against a fresh deployment with these fixes:
1. First apply will create resources with correct diagnostic settings
2. Azure platform will add NSG rules (as expected)
3. Second plan will show only the Azure-managed NSG rules, not diagnostic setting changes

## Validation

To validate these fixes:

```bash
# Clean environment
terraform destroy -auto-approve

# Apply with fixes
terraform apply -auto-approve

# Check for idempotency (expect only Azure-managed NSG rules)
terraform plan
```

Expected result: Plan should show zero changes except for NSG security rules added by Azure Container Apps platform (which is expected behavior).

## References

- [Azure Container Apps Networking](https://learn.microsoft.com/en-us/azure/container-apps/networking)
- [AVM Diagnostic Settings Pattern](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/#diagnostic-settings)
- [Container Apps Environment Network Requirements](https://learn.microsoft.com/en-us/azure/container-apps/firewall-integration)
