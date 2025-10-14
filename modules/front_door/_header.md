# Azure Front Door Module

This module creates an Azure Front Door (Standard or Premium) with custom domain support and TLS termination using certificates from Azure Key Vault.

## Features

- Support for Standard and Premium SKUs
- Optional Web Application Firewall (WAF) protection (Premium SKU only)
- Optional Private Link integration with Azure Container Apps Environment (Premium SKU only)
- Health probes and load balancing
- Diagnostic settings integration with Log Analytics
- Caching configuration

## Private Link Integration

When `enable_private_link` is set to `true`, the module configures Azure Front Door to connect to the Container Apps Environment via Azure Private Link instead of over the public internet. This provides enhanced security by keeping traffic within the Microsoft backbone network.

**Requirements for Private Link:**
- Front Door SKU must be `Premium_AzureFrontDoor`
- `container_apps_environment_id` must be provided
- The Container Apps Environment must support private link connections

For more information, see [Integrate Azure Front Door with Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/how-to-integrate-with-azure-front-door).

