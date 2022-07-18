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
param plan_enable_zone_redundancy bool = false

// Create a Windows Sample App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  tags: tags
  name: 'plan-azure-bicep-app-service-test'
  location: location
  sku: {
    name: 'P1V3'
    tier: 'PremiumV3'
    capacity: plan_enable_zone_redundancy ? 3 : 1
  }
  properties: {
    zoneRedundant: plan_enable_zone_redundancy
  }
}

param log_n string = 'log-test'
param appi_n string = 'appi-test'
// ------------------------------------------------------------------------------------------------
// REPLACE
// '../main.bicep' by the ref with your version, for example:
// 'br:bicephubdev.azurecr.io/bicep/modules/app:v1'
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// Windows App Service examples
// ------------------------------------------------------------------------------------------------
module Http '../main.bicep' = {
  name: 'Http'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('Http-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
  }
}

module HttpS '../main.bicep' = {
  name: 'HttpS'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('HttpS-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.1'
  }
}

module TLS12 '../main.bicep' = {
  name: 'TLS12'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('TLS12-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
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
module VnetIntegrationHttp '../main.bicep' = {
  name: 'VnetIntegration'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('VnetIntegration-Http-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

module VnetIntegrationHttps '../main.bicep' = {
  name: 'VnetIntegrationHttps'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('VnetIntegration-Https-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.0'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
  }
}

// ------------------------------------------------------------------------------------------------
// App Service PE
// ------------------------------------------------------------------------------------------------
module PEHttp '../main.bicep' = {
  name: 'PE'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('PE-Http-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: true
  }
}

module PEHttps '../main.bicep' = {
  name: 'PEHttps'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('PE-Https-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
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
module VnetIntegrationPE '../main.bicep' = {
  name: 'VnetIntegrationPE'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('VnetIntegration-PE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: false // since this pdnsz to vnet Link already exists from previous module deployment we do not deploy it again
  }
}

// ------------------------------------------------------------------------------------------------
// Linux App Service examples
// ------------------------------------------------------------------------------------------------
resource LinuxAppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  tags: tags
  name: 'plan-azure-bicep-linux-app-service-test'
  location: location
  kind: 'linux'
  sku: {
    name: 'S2'
    tier: 'Standard'
    capacity: plan_enable_zone_redundancy ? 3 : 1
  }
  properties: {
    reserved: true
    zoneRedundant: plan_enable_zone_redundancy
  }
}

module LinuxHttp '../main.bicep' = {
  name: 'LinuxHttp'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('Linux-Http-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: LinuxAppServicePlan.id
    app_min_tls_v: '1.0'
  }
}

module LinuxHttpS '../main.bicep' = {
  name: 'LinuxHttpS'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('Linux-HttpS-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: LinuxAppServicePlan.id
    app_min_tls_v: '1.1'
  }
}

module LinuxTLS12 '../main.bicep' = {
  name: 'LinuxTLS12'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('Linux-TLS-12-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: LinuxAppServicePlan.id
    app_min_tls_v: '1.2'
  }
}

// ------------------------------------------------------------------------------------------------
// Deploy Log Analytics Workspace
// ------------------------------------------------------------------------------------------------

module log '../modules/log/log.bicep' = {
  name: log_n
  params: {
    location: location
    name: log_n
  }
}

// ------------------------------------------------------------------------------------------------
// Deploy App Insight Service
// ------------------------------------------------------------------------------------------------

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: appi_n
  location: location
  kind: 'string'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: log.outputs.id
  }
}

// ------------------------------------------------------------------------------------------------
// Test Appi Link
// ------------------------------------------------------------------------------------------------

module AppiWindows '../main.bicep' = {
  name: 'AppiWindows'
  params: {
    tags: tags
    location: location
    app_enable_https_only: true
    app_n: take('Appi-Windows-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.1'
    appi_k: appi.properties.InstrumentationKey
  }
}

module AppiWindowsVnet '../main.bicep' = {
  name: 'AppiWindowsVnet'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('Appi-Windows-VnetIntegration-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
    appi_k: appi.properties.InstrumentationKey
  }
}

module AppiWindowsVnetPE '../main.bicep' = {
  name: 'AppiWindowsVnetPE'
  params: {
    tags: tags
    location: location
    app_enable_https_only: false
    app_n: take('Appi-Windows-VnetIntegration-PE-${guid(subscription().id, resourceGroup().id, tags.env)}', 60)
    plan_id: appServicePlan.id
    app_min_tls_v: '1.2'
    snet_plan_vnet_integration_id: vnetApp.properties.subnets[0].id
    snet_app_vnet_pe_id: vnetApp.properties.subnets[1].id
    pdnsz_app_id: pdnsz.id
    app_pe_create_virtual_network_link: false // since this pdnsz to vnet Link already exists from previous module deployment we do not deploy it again
    appi_k: appi.properties.InstrumentationKey
  }
}
