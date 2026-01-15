# Exception policy for minimal-configuration example
# This file creates exceptions for APRL (Azure Proactive Resiliency Library) policies
# that may not be applicable to this example configuration.

package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# Add policy exceptions here as needed
# Example format:
# exception contains rules if {
#   rules := ["policy_rule_name"]
# }

# Note: This file is for conftest APRL/AVMSEC policy exceptions only.
# It does NOT affect the Terraform idempotency check.
# 
# Known Azure platform behaviors that cause expected plan changes:
# - NSG security rules: Azure Container Apps platform adds rules automatically
# - Private DNS zones: numberOfRecordSets and numberOfVirtualNetworkLinks are computed values
#
# The diagnostic setting log_analytics_destination_type issue has been addressed
# by explicitly setting the value to null in the module code.
# See: https://github.com/Azure/terraform-azurerm-avm-res-operationalinsights-workspace/issues/114
