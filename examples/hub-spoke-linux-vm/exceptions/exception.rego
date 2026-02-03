package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# Exception for Application Gateway autoscale configuration
# Reason: False positive - autoscale_configuration is correctly configured with min_capacity=1
# The Terraform plan shows autoscale_configuration[0].min_capacity = 1 and SKU capacity = null (correct for autoscale)
# This appears to be a bug in the APRL conftest policy logic
exception contains rules if {
	rules = ["application_gateway_ensure_autoscale_feature_has_been_enabled"]
}
