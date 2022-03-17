targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
param location string = 'eastus2'
// Sample tags parameters
var tags = {
  project: 'test'
  env: 'qa'
}

// Sample App Service Plan parameters
param plan_n string = 'plan-azure-bicep-app-service-test'
param plan_sku_code string = 'P1V3'
param plan_sku_tier string = 'PremiumV3'
param plan_enable_zone_redundancy bool = false

// Create a Sample App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  tags: tags
  name: plan_n
  location: location
  sku: {
    name: plan_sku_code
    tier: plan_sku_tier
    capacity: plan_enable_zone_redundancy ? 3 : 1
  }
  properties: {
    zoneRedundant: plan_enable_zone_redundancy
  }
}

// ------------------------------------------------------------------------------------------------
// REPLACE
// '../main.bicep' by the ref with your version, for example:
// 'br:bicephubdev.azurecr.io/bicep/modules/app:v1'
// ------------------------------------------------------------------------------------------------
module Http '../main.bicep' = {
  name: 'Http'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('Http-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
  }
}

module HttpS '../main.bicep' = {
  name: 'HttpS'
  params: {
    location: location
    app_enable_https_only: true
    app_names: take('HttpS-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.1'
  }
}

module ABHttp '../main.bicep' = {
  name: 'ABHttp'
  params: {
    location: location
    app_enable_https_only: false
    app_names: '${take('A-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('B-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
  }
}

module ABHttps '../main.bicep' = {
  name: 'ABHttps'
  params: {
    location: location
    app_enable_https_only: true
    app_names: '${take('A-HttpS-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('B-HttpS-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
  }
}

// ------------------------------------------------------------------------------------------------
// App Service Networking Configurations Examples
// ------------------------------------------------------------------------------------------------
var subnets = [
  {
    name: 'snet-vnet-integration-azure-bicep-app-service'
    subnetPrefix: '192.160.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
  }
  {
    name: 'snet-app-pe-azure-bicep-app-service'
    subnetPrefix: '192.160.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    delegations: []
  }
]

resource vnetApp 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-azure-bicep-app-service'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.160.0.0/23'
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        delegations: subnet.delegations
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      }
    }]
  }
}

resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  tags: tags
}

// ------------------------------------------------------------------------------------------------
// App Service Vnet Integration
// ------------------------------------------------------------------------------------------------
module VnetIntegration '../main.bicep' = {
  name: 'VnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('VnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

module ABVnetIntegration '../main.bicep' = {
  name: 'ABCVnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: '${take('A-VnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('B-VnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

// ------------------------------------------------------------------------------------------------
// App Service PE
// ------------------------------------------------------------------------------------------------
module VnetPE '../main.bicep' = {
  name: 'VnetPE'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('VnetPE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: true
  }
}

module ABVnetPE '../main.bicep' = {
  name: 'ABVnetPE'
  params: {
    location: location
    app_enable_https_only: false
    app_names: '${take('A-VnetPE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('B-VnetPE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: false // since this pdnsz to vnet Link already exists from previous module deployment we do not deploy it again
  }
}

// ------------------------------------------------------------------------------------------------
// App Service Vnet Integration & PE
// ------------------------------------------------------------------------------------------------
module VnetIntegrationVnetPE '../main.bicep' = {
  name: 'VnetIntegrationVnetPE'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('VnetIntegrationVnetPE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: false // since this pdnsz to vnet Link already exists from previous module deployment we do not deploy it again
  }
}
