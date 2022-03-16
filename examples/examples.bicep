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

module DeployOneApp '../main.bicep' = {
  name: 'deployOneApp'
  params: {
    location: location
    app_enable_https_only: false
    app_names: 'appA-${guid(subscription().id, resourceGroup().id, tags.env)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
  }
}

module DeployOneAppHttps '../main.bicep' = {
  name: 'deployOneAppHttps'
  params: {
    location: location
    app_enable_https_only: true
    app_names: 'appHttpsA-${guid(subscription().id, resourceGroup().id, tags.env)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.1'
  }
}

module DeployMultipleApps '../main.bicep' = {
  name: 'deployMultipleApp'
  params: {
    location: location
    app_enable_https_only: false
    app_names: 'appMultiA-${guid(subscription().id, resourceGroup().id, tags.env)},appMultiB${guid(subscription().id, resourceGroup().id, tags.env)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
  }
}

module DeployMultipleAppsHttps '../main.bicep' = {
  name: 'deployMultipleAppHttps'
  params: {
    location: location
    app_enable_https_only: true
    app_names: 'appMultiHttpsA-${guid(subscription().id, resourceGroup().id, tags.env)},appMultiHttpB${guid(subscription().id, resourceGroup().id, tags.env)}'
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

module DeployOneAppVnetIntegration '../main.bicep' = {
  name: 'DeployOneAppVnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: 'appAVnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

module DeployMultipleAppsVnetIntegration '../main.bicep' = {
  name: 'DeployMultipleAppsVnetIntegration'
  params: {
    location: location
    app_enable_https_only: false
    app_names: 'appAVnetIntegrationA${guid(subscription().id, resourceGroup().id, tags.env)},appAVnetIntegrationB${guid(subscription().id, resourceGroup().id, tags.env)}'
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}
