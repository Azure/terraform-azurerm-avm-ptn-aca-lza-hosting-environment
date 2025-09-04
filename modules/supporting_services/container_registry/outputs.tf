output "id" { value = module.acr.resource_id }
output "name" { value = module.acr.name }
output "login_server" { value = "${module.acr.name}.azurecr.io" }
output "agent_pool_name" {
  value = try(azapi_resource.agent_pool[0].name, "")
}
output "uai_id" { value = module.uai.resource_id }
