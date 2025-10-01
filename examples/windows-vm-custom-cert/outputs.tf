output "certificate_thumbprint" {
  description = "Certificate thumbprint"
  value       = sha1(tls_self_signed_cert.cert.cert_pem)
}

output "container_apps_environment_id" {
  description = "Container Apps Environment ID"
  value       = module.aca_lza_hosting.container_apps_environment_id
}

output "resource_group_name" {
  description = "Created resource group name"
  value       = module.aca_lza_hosting.resource_group_name
}

output "windows_vm_id" {
  description = "Windows VM resource ID"
  value       = module.aca_lza_hosting.windows_vm_id
}
