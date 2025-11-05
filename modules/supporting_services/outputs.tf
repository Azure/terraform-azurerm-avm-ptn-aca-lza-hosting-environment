output "container_registry_id" {
  description = "ACR resource ID"
  value       = try(module.container_registry[0].id, null)
}

output "container_registry_login_server" {
  description = "ACR login server"
  value       = try(module.container_registry[0].login_server, null)
}

output "container_registry_name" {
  description = "ACR name"
  value       = try(module.container_registry[0].name, null)
}

output "container_registry_uai_id" {
  description = "ACR user assigned identity id"
  value       = try(module.container_registry[0].uai_id, null)
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = try(module.key_vault[0].id, null)
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = try(module.key_vault[0].name, null)
}

output "resource_id" {
  description = "The resource ID of the primary resource deployed by this module (uses storage account as primary)"
  value       = try(module.storage[0].id, null)
}

output "storage_account_id" {
  description = "Storage Account ID"
  value       = try(module.storage[0].id, null)
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = try(module.storage[0].name, null)
}
