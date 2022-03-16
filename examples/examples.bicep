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

module OneAppHttp '../main.bicep' = {
  name: 'OneAppHttp'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('OneAppHttp-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
  }
}

module OneAppHttps '../main.bicep' = {
  name: 'OneAppHttps'
  params: {
    location: location
    app_enable_https_only: true
    app_names: take('OneAppHttps-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.1'
  }
}

module MultiApp '../main.bicep' = {
  name: 'MultiApp'
  params: {
    location: location
    app_enable_https_only: false
    app_names: '${take('MultiAppA-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('MultiAppB${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
  }
}

module MultiAppHttps '../main.bicep' = {
  name: 'MultiAppHttps'
  params: {
    location: location
    app_enable_https_only: true
    app_names: '${take('MultiAppAHttps-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('MultiAppBHttps${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
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

module OneAppHttpVnetIntegration '../main.bicep' = {
  name: 'OneAppHttpVnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: take('OneAppHttpVnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

module MultiAppHttpVnetIntegration '../main.bicep' = {
  name: 'MultiAppHttpVnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: '${take('MultiAppAVnetIntegration${guid(subscription().id, resourceGroup().id, tags.env)}', 60)},${take('MultiAppBVnetIntegration${guid(subscription().id, resourceGroup().id, tags.env)}', 60)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}
