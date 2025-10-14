output "id" { value = module.acr.resource_id }
output "name" { value = module.acr.name }
output "login_server" { value = "${module.acr.name}.azurecr.io" }
output "uai_id" { value = module.uai.resource_id }
