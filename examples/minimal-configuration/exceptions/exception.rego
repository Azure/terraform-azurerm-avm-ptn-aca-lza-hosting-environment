# Exception policy for minimal-configuration example
# This policy ignores known Azure-managed changes that occur after initial deployment

package conftest

# Ignore Azure-managed NSG security rules that are added automatically by Container Apps
# These rules are added by the Azure platform and don't represent configuration drift
deny[msg] {
  input.resource_changes[_].type == "azurerm_network_security_group"
  input.resource_changes[_].change.actions[_] == "update"
  input.resource_changes[_].change.after.security_rule
  
  msg := sprintf("Ignoring NSG security_rule changes - these are managed by Azure Container Apps platform", [])
}

# Ignore computed output changes in AzAPI private DNS zones
# numberOfRecordSets and numberOfVirtualNetworkLinks are read-only computed values
deny[msg] {
  input.resource_changes[_].type == "azapi_resource"
  contains(input.resource_changes[_].address, "private_dns_zone")
  input.resource_changes[_].change.actions[_] == "update"
  
  msg := sprintf("Ignoring private DNS zone output changes - numberOfRecordSets and numberOfVirtualNetworkLinks are computed", [])
}

# Ignore data_endpoint_host_names changes in Container Registry
# This is a computed value that gets populated after ACR creation
deny[msg] {
  input.resource_changes[_].type == "azurerm_container_registry"
  input.resource_changes[_].change.after.data_endpoint_host_names
  
  msg := sprintf("Ignoring ACR data_endpoint_host_names - this is a computed value", [])
}

# Allow diagnostic setting updates for log_analytics_destination_type
# This is an expected update to align with AVM standards
allow {
  input.resource_changes[_].type == "azurerm_monitor_diagnostic_setting"
  input.resource_changes[_].change.after.log_analytics_destination_type == "Dedicated"
}
