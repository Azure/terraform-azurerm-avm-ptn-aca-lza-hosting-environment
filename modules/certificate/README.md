# Certificate Module

This module manages TLS certificates for Application Gateway by either storing provided certificates in Key Vault or generating self-signed certificates using deployment scripts.

## Features

- **Certificate Storage**: Stores provided base64-encoded PFX certificates in Azure Key Vault
- **Self-Signed Generation**: Automatically generates self-signed certificates when no certificate is provided
- **Network-Aware**: Uses deployment scripts with VNet integration to access network-restricted Key Vaults
- **Role-Based Access**: Configures appropriate RBAC permissions for certificate access

## Usage

```hcl
module "certificate" {
  source = "./modules/certificate"

  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  resource_prefix     = var.resource_prefix

  key_vault_id              = var.key_vault_id
  storage_account_name      = var.storage_account_name
  deployment_subnet_id      = var.deployment_subnet_id
  app_gateway_principal_id  = module.app_gateway.user_assigned_identity_principal_id
  certificate_key_name      = var.certificate_key_name
  certificate_subject_name  = var.certificate_subject_name
  base64_certificate        = var.base64_certificate
}
```

## Certificate Flow

1. **If `base64_certificate` is provided**: The certificate is stored as a Key Vault secret
2. **If `base64_certificate` is empty**: A deployment script generates a self-signed certificate within the VNet

## Network Requirements

The deployment script requires:
- A subnet for the deployment script container
- Network connectivity to the Key Vault (either private endpoint or service endpoint)
- Storage account access for deployment script artifacts

## Providers

- `azurerm`: >= 3.115.0
- `azapi`: >= 1.0 (for deployment scripts with VNet integration)

## Outputs

- `secret_uri`: The versionless Key Vault secret URI for the certificate
