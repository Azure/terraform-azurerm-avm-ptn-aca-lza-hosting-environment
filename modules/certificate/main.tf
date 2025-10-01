terraform {
  required_version = ">= 1.6"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115.0"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  key_vault_secret_user_role_guid = "4633458b-17de-408a-b874-0445c86b69e6"
  needs_deployment_script         = true # Always use deployment script for network-restricted Key Vault access
  # PowerShell script for provided certificate storage
  provided_cert_script = <<-EOT
    param(
        [Parameter(Mandatory = $true)]
        [string] $KeyVaultName,

        [Parameter(Mandatory = $true)]
        [string] $CertName,

        [Parameter(Mandatory = $true)]
        [string] $CertificateValue
    )

    # Check if certificate already exists
    $existingCert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -ErrorAction 'SilentlyContinue'

    if (-not $existingCert) {
        # Import the provided certificate
        $certBytes = [System.Convert]::FromBase64String($CertificateValue)
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certBytes)

        # Store the certificate in Key Vault
        $secret = Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $CertName -SecretValue (ConvertTo-SecureString -String $CertificateValue -AsPlainText -Force) -ContentType "application/x-pkcs12"
        Write-Verbose ('Stored provided certificate [{0}] in key vault [{1}]' -f $CertName, $KeyVaultName) -Verbose

        $secretUrl = $secret.Id
    } else {
        Write-Verbose ('Certificate [{0}] already exists in key vault [{1}]' -f $CertName, $KeyVaultName) -Verbose
        $secretUrl = $existingCert.SecretId
    }

    # Write into Deployment Script output stream
    $DeploymentScriptOutputs = @{
        secretUrl = $secretUrl
    }
  EOT
  # PowerShell script for self-signed certificate generation
  self_signed_cert_script = <<-EOT
    param(
        [Parameter(Mandatory = $true)]
        [string] $KeyVaultName,

        [Parameter(Mandatory = $true)]
        [string] $CertName,

        [Parameter(Mandatory = $false)]
        [string] $CertSubjectName = 'CN=contoso.com'
    )

    $certificate = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -ErrorAction 'SilentlyContinue'

    if (-not $certificate) {
        $policyInputObject = @{
            SecretContentType = 'application/x-pkcs12'
            SubjectName       = $CertSubjectName
            IssuerName        = 'Self'
            ValidityInMonths  = 12
            ReuseKeyOnRenewal = $true
        }
        $certPolicy = New-AzKeyVaultCertificatePolicy @policyInputObject

        $null = Add-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -CertificatePolicy $certPolicy
        Write-Verbose ('Initiated creation of certificate [{0}] in key vault [{1}]' -f $CertName, $KeyVaultName) -Verbose

        while (-not (Get-AzKeyVaultCertificateOperation -VaultName $KeyVaultName -Name $CertName).Status -eq 'completed') {
            Write-Verbose 'Waiting 10 seconds for certificate creation' -Verbose
            Start-Sleep 10
        }

        Write-Verbose 'Certificate created' -Verbose
    }

    $secretId = $certificate.SecretId
    while ([String]::IsNullOrEmpty($secretId)) {
        Write-Verbose 'Waiting 10 seconds until certificate can be fetched' -Verbose
        Start-Sleep 10
        $certificate = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -ErrorAction 'Stop'
        $secretId = $certificate.SecretId
    }

    # Write into Deployment Script output stream
    $DeploymentScriptOutputs = @{
        secretUrl = $secretId
    }
  EOT
  use_self_signed_cert    = length(trimspace(var.base64_certificate)) == 0
}

# Parse Key Vault information from the resource ID
locals {
  _kv_id_segments = split("/", local._kv_id_trimmed)
  _kv_id_trimmed  = trimspace(var.key_vault_id)
  kv_name         = local._kv_id_segments[8]
  kv_rg_name      = local._kv_id_segments[4]
  kv_subscription = local._kv_id_segments[2]
}

data "azurerm_key_vault" "kv" {
  name                = local.kv_name
  resource_group_name = local.kv_rg_name
}

data "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create a managed identity for the deployment script (used for both self-signed cert generation and provided cert storage)
resource "azurerm_user_assigned_identity" "cert_uai" {
  location            = var.location
  name                = "${var.resource_prefix}-certManagedIdentity"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Assign Key Vault Administrator role to the deployment script UAI
resource "azurerm_role_assignment" "cert_uai_kv_admin" {
  principal_id       = azurerm_user_assigned_identity.cert_uai.principal_id
  scope              = var.key_vault_id
  principal_type     = "ServicePrincipal"
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483" # Key Vault Administrator
}

# Assign storage role to deployment script UAI
resource "azurerm_role_assignment" "cert_uai_storage_admin" {
  principal_id       = azurerm_user_assigned_identity.cert_uai.principal_id
  scope              = data.azurerm_storage_account.storage.id
  principal_type     = "ServicePrincipal"
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd" # Storage File Data Privileged Contributor
}

# Deployment script for certificate management (handles both self-signed generation and provided cert storage using AzAPI)
resource "azapi_resource" "certificate_deployment_script" {
  name      = "${substr(var.resource_prefix, 0, 4)}-certDeploymentScript"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Resources/deploymentScripts@2023-08-01"
  body = {
    kind     = "AzurePowerShell"
    location = var.location
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.cert_uai.id}" = {}
      }
    }
    properties = {
      forceUpdateTag      = uuid()
      azPowerShellVersion = "14.0"
      retentionInterval   = "P1D"
      arguments           = local.use_self_signed_cert ? "-KeyVaultName \"${local.kv_name}\" -CertName \"${var.certificate_key_name}\" -CertSubjectName \"${var.certificate_subject_name}\"" : "-KeyVaultName \"${local.kv_name}\" -CertName \"${var.certificate_key_name}\" -CertificateValue \"${var.base64_certificate}\""
      scriptContent       = local.use_self_signed_cert ? local.self_signed_cert_script : local.provided_cert_script
      cleanupPreference   = "OnExpiration"
      storageAccountSettings = {
        storageAccountName = var.storage_account_name
      }
      containerSettings = {
        subnetIds = [
          {
            id = var.deployment_subnet_id
          }
        ]
      }
    }
  }
  response_export_values = ["*"]
  tags                   = var.tags

  depends_on = [
    azurerm_role_assignment.cert_uai_kv_admin,
    azurerm_role_assignment.cert_uai_storage_admin
  ]
}

# Assign the App Gateway user assigned identity the role to read the secret
resource "azurerm_role_assignment" "kv_secret_user_role" {
  principal_id       = var.app_gateway_principal_id
  scope              = var.key_vault_id
  principal_type     = "ServicePrincipal"
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.key_vault_secret_user_role_guid}"
}
