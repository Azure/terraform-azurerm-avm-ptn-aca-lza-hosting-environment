output "container_registry_id" {
  description = "ACR resource ID"
  value       = var.deploy_acr ? module.acr[0].resource_id : var.existing_acr_id
}

output "container_registry_login_server" {
  description = "ACR login server"
  value       = var.deploy_acr ? "${module.acr[0].name}.azurecr.io" : (local.existing_acr_name != null ? "${local.existing_acr_name}.azurecr.io" : null)
}

output "container_registry_name" {
  description = "ACR name"
  value       = var.deploy_acr ? module.acr[0].name : local.existing_acr_name
}

output "container_registry_uai_id" {
  description = "ACR user assigned identity id"
  value       = local.use_acr ? module.acr_uai[0].resource_id : null
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = module.kv.resource_id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.kv.name
}

output "resource_id" {
  description = "The resource ID of the primary resource deployed by this module (uses storage account as primary)"
  value       = module.st.resource_id
}

output "storage_account_id" {
  description = "Storage Account ID"
  value       = module.st.resource_id
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = module.st.name
}
