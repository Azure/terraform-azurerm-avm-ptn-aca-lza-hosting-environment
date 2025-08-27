###############################################
# Locals implementing naming logic            #
###############################################

# Static maps for abbreviations
locals {
  resource_type_abbreviations = {
    applicationGateway       = "agw"
    applicationInsights      = "appi"
    appService               = "app"
    azureFirewall            = "azfw"
    bastion                  = "bas"
    containerAppsEnvironment = "cae"
    containerRegistry        = "cr"
    cosmosDbNoSql            = "cosno"
    frontDoor                = "afd"
    frontDoorEndpoint        = "fde"
    frontDoorWaf             = "fdfp"
    keyVault                 = "kv"
    logAnalyticsWorkspace    = "log"
    managedIdentity          = "id"
    networkInterface         = "nic"
    networkSecurityGroup     = "nsg"
    privateEndpoint          = "pep"
    privateLinkService       = "pls"
    publicIpAddress          = "pip"
    resourceGroup            = "rg"
    routeTable               = "rt"
    serviceBus               = "sb"
    serviceBusQueue          = "sbq"
    serviceBusTopic          = "sbt"
    storageAccount           = "st"
    virtualMachine           = "vm"
    virtualNetwork           = "vnet"
    redisCache               = "redis"
    cognitiveAccount         = "cog"
    openAiDeployment         = "oaidep"
    azureAISearch            = "srch"
    documentIntelligence     = "di"
    eventGridSystemTopic     = "egst"
    eventGridSubscription    = "evgs"
  }

  region_abbreviations = {
    australiacentral   = "auc"
    australiacentral2  = "auc2"
    australiaeast      = "aue"
    australiasoutheast = "ause"
    brazilsouth        = "brs"
    brazilsoutheast    = "brse"
    canadacentral      = "canc"
    canadaeast         = "cane"
    centralindia       = "cin"
    centralus          = "cus"
    centraluseuap      = "cuseuap"
    eastasia           = "ea"
    eastus             = "eus"
    eastus2            = "eus2"
    eastus2euap        = "eus2euap"
    francecentral      = "frc"
    francesouth        = "frs"
    germanynorth       = "gern"
    germanywestcentral = "gerwc"
    japaneast          = "jae"
    japanwest          = "jaw"
    jioindiacentral    = "jioinc"
    jioindiawest       = "jioinw"
    koreacentral       = "koc"
    koreasouth         = "kors"
    northcentralus     = "ncus"
    northeurope        = "neu"
    norwayeast         = "nore"
    norwaywest         = "norw"
    southafricanorth   = "san"
    southafricawest    = "saw"
    southcentralus     = "scus"
    southeastasia      = "sea"
    southindia         = "sin"
    swedencentral      = "swc"
    switzerlandnorth   = "swn"
    switzerlandwest    = "sww"
    uaecentral         = "uaec"
    uaenorth           = "uaen"
    uksouth            = "uks"
    ukwest             = "ukw"
    westcentralus      = "wcus"
    westeurope         = "weu"
    westindia          = "win"
    westus             = "wus"
    westus2            = "wus2"
    westus3            = "wus3"
  }

  unique_id_short     = substr(var.unique_id, 0, 5)
  resource_type_token = "RES_TYPE"

  # Normalize location key to lower for the map lookup
  location_key = lower(var.location)

  naming_base             = "${local.resource_type_token}-${var.workload_name}-${var.environment}-${lookup(local.region_abbreviations, local.location_key, local.location_key)}"
  naming_base_unique      = "${local.resource_type_token}-${var.workload_name}-${local.unique_id_short}-${var.environment}-${lookup(local.region_abbreviations, local.location_key, local.location_key)}"
  naming_base_no_workload = "${local.resource_type_token}-${var.environment}-${lookup(local.region_abbreviations, local.location_key, local.location_key)}"

  # Helper replacements mirroring Bicep replace/take/toLower
  replace_token = replace(local.naming_base, local.resource_type_token, "${local.resource_type_abbreviations["applicationGateway"]}")
}
