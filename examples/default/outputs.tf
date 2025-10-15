output "law_id" {
  description = "Log Analytics Workspace resource ID"
  value       = module.aca_lza_hosting.log_analytics_workspace_id
}

output "vm_admin_password" {
  description = "Generated VM admin password (sensitive - for debugging only)"
  value       = random_password.vm_admin.result
  sensitive   = true
}
