# Front Door Premium with Private Link Example

This example demonstrates how to deploy the Azure Container Apps Landing Zone Accelerator with Azure Front Door Premium as the ingress solution, using Private Link to securely connect to the internal Container Apps Environment.

## Key Features

- **Azure Front Door Premium**: Automatically configured when Front Door ingress is selected
- **Private Link**: Enabled by default to securely connect Front Door to the internal Container Apps Environment
- **Optional WAF**: Web Application Firewall can be optionally enabled (disabled in this example)
- **No Application Gateway**: Front Door replaces Application Gateway for ingress
- **Sample Application**: Deployed to demonstrate connectivity

## Architecture

When using Front Door with the internal Container Apps Environment:
1. Front Door Premium SKU is mandatory (required for Private Link support)
2. Private Link is automatically enabled to connect to the internal Container Apps Environment
3. Traffic flows through Azure's private backbone network instead of the public internet
4. WAF protection is optional and can be enabled via the `front_door_enable_waf` variable

