###############################################
# Outputs                                     #
###############################################

# Object output of computed resource names
locals {
  resource_names = {
    resourceGroup                          = (trimspace(var.spoke_resource_group_name) != "" ? var.spoke_resource_group_name : "${local.resource_type_abbreviations.resourceGroup}-${var.workload_name}-spoke-${var.environment}-${lookup(local.region_abbreviations, local.location_key, local.location_key)}")
    vnetSpoke                              = "${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.virtualNetwork)}-spoke"
    vnetHub                                = "${replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.virtualNetwork)}-hub"
    applicationGateway                     = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.applicationGateway)
    applicationGatewayPip                  = "${local.resource_type_abbreviations.publicIpAddress}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.applicationGateway)}"
    applicationGatewayUserAssignedIdentity = "${local.resource_type_abbreviations.managedIdentity}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.applicationGateway)}-KeyVaultSecretUser"
    applicationGatewayNsg                  = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.applicationGateway)}"
    pepNsg                                 = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.privateEndpoint)}"
    applicationInsights                    = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.applicationInsights)
    azureFirewall                          = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.azureFirewall)
    azureFirewallPip                       = "${local.resource_type_abbreviations.publicIpAddress}-${replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.azureFirewall)}"
    bastion                                = replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.bastion)
    bastionNsg                             = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.bastion)}"
    bastionPip                             = "${local.resource_type_abbreviations.publicIpAddress}-${replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.bastion)}"
    containerAppsEnvironment               = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.containerAppsEnvironment)
    containerAppsEnvironmentNsg            = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.containerAppsEnvironment)}"
    containerRegistry                      = substr(lower(replace(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.containerRegistry), "-", "")), 0, 50)
    containerRegistryPep                   = "${local.resource_type_abbreviations.privateEndpoint}-${lower(replace(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.containerRegistry), "-", ""))}"
    containerRegistryUserAssignedIdentity  = "${local.resource_type_abbreviations.managedIdentity}-${lower(replace(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.containerRegistry), "-", ""))}-AcrPull"
    redisCache                             = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.redisCache)
    redisCachePep                          = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.redisCache)}"
    openAiAccount                          = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.cognitiveAccount)
    openAiDeployment                       = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.openAiDeployment)
    cosmosDbNoSql                          = lower(substr(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.cosmosDbNoSql), 0, 44))
    cosmosDbNoSqlPep                       = "${local.resource_type_abbreviations.privateEndpoint}-${lower(substr(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.cosmosDbNoSql), 0, 44))}"
    frontDoorProfile                       = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.frontDoor)
    # Bicep parity: take 24, trim trailing hyphen
    keyVault = (
      endswith(substr(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.keyVault), 0, 24), "-")
      ? substr(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.keyVault), 0, 23)
      : substr(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.keyVault), 0, 24)
    )
    keyVaultPep                 = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.keyVault)}"
    logAnalyticsWorkspace       = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.logAnalyticsWorkspace)
    routeTable                  = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.routeTable)
    serviceBus                  = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.serviceBus)
    serviceBusPep               = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.serviceBus)}"
    storageAccount              = lower(substr(replace(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.storageAccount), "-", ""), 0, 24))
    storageAccountPep           = "${local.resource_type_abbreviations.privateEndpoint}-${lower(replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.storageAccount))}"
    vmJumpBox                   = replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.virtualMachine)
    vmJumpBoxNsg                = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.virtualMachine)}"
    vmJumpBoxNic                = "${local.resource_type_abbreviations.networkInterface}-${replace(local.naming_base_no_workload, local.resource_type_token, local.resource_type_abbreviations.virtualMachine)}"
    frontDoor                   = replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.frontDoor)
    frontDoorPrivateLinkService = "${local.resource_type_abbreviations.privateLinkService}-${replace(local.naming_base, local.resource_type_token, local.resource_type_abbreviations.frontDoor)}"
    azureAISearch               = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.azureAISearch)
    azureAISearchPep            = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.azureAISearch)}"
    documentIntelligence        = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.documentIntelligence)
    documentIntelligencePep     = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.documentIntelligence)}"
    eventGridSystemTopic        = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.eventGridSystemTopic)
    eventGridSystemTopicPep     = "${local.resource_type_abbreviations.privateEndpoint}-${replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.eventGridSystemTopic)}"
    eventGridSubscription       = replace(local.naming_base_unique, local.resource_type_token, local.resource_type_abbreviations.eventGridSubscription)
    workloadCertificate         = "${var.workload_name}-cert"
    acrDeploymentPoolNsg        = "${local.resource_type_abbreviations.networkSecurityGroup}-${replace(local.naming_base, local.resource_type_token, "deploymentpool")}"
  }
}

output "resources_names" {
  description = "Computed resource names"
  value       = local.resource_names
}

output "resource_type_abbreviations" {
  description = "Resource type abbreviations"
  value       = local.resource_type_abbreviations
}
