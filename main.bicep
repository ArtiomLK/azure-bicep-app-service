// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
@description('Az Resources tags')
param tags object = {}
@description('Az Resource deployment location')
param location string = resourceGroup().location

// ------------------------------------------------------------------------------------------------
// Application parameters
// ------------------------------------------------------------------------------------------------
@description('App Service Name For example: applicationA')
param app_n string

@description('App Service Plan resource ID')
param plan_id string

@description('App Insights Instrumentation key')
@secure()
param appi_k string = ''

@description('Enable only HTTPS traffic through App Service')
param app_enable_https_only bool = false

// ------------------------------------------------------------------------------------------------
// Application Topology parameters
// ------------------------------------------------------------------------------------------------
@description('Minimum TLS Version allowed')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param app_min_tls_v string = '1.2'

@description('Enable app Virtual Network Integration by providing a subnet ID')
param snet_plan_vnet_integration_id string = ''

@description('subnet ID to Enable App Private Endpoints Connections')
param snet_app_vnet_pe_id string = ''

@description('Create a Private DNS Zone link to the Private Endpoint Vnet. If the link exists the deployment fails')
param app_pe_create_virtual_network_link bool = false

// pdnszgroup - Add A records to PDNSZ for app pe
@description('App Service Private DNS Zone Resource ID where the A records will be written')
param pdnsz_app_id string = ''
var pdnsz_app_parsed_id = empty(pdnsz_app_id) ? {
  sub_id: ''
  rg_n: ''
  res_n: ''
} : {
  sub_id: substring(substring(pdnsz_app_id, indexOf(pdnsz_app_id, 'subscriptions/') + 14), 0, indexOf(substring(pdnsz_app_id, indexOf(pdnsz_app_id, 'subscriptions/') + 14), '/'))
  rg_n: substring(substring(pdnsz_app_id, indexOf(pdnsz_app_id, 'resourceGroups/') + 15), 0, indexOf(substring(pdnsz_app_id, indexOf(pdnsz_app_id, 'resourceGroups/') + 15), '/'))
  res_n: substring(pdnsz_app_id, lastIndexOf(pdnsz_app_id, '/')+1)
}

var app_properties = {
  serverFarmId: plan_id
  httpsOnly: app_enable_https_only
 }

var app_properties_w_vnet_integration = union(app_properties, {
  virtualNetworkSubnetId: snet_plan_vnet_integration_id
})

// ------------------------------------------------------------------------------------------------
// Deploy Azure Resources
// ------------------------------------------------------------------------------------------------
resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: app_n
  location: location
  properties: empty(snet_plan_vnet_integration_id) ? app_properties : app_properties_w_vnet_integration
  tags: tags
}

resource appServiceWebSettings 'Microsoft.Web/sites/config@2020-06-01' = if(!empty(appi_k)) {
  parent: appService
  name: 'web'
  properties: {
    minTlsVersion: app_min_tls_v
    detailedErrorLoggingEnabled : !empty(appi_k)
    httpLoggingEnabled: !empty(appi_k)
    requestTracingEnabled: !empty(appi_k)
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (!empty(snet_app_vnet_pe_id)) {
  tags: tags
  name: 'pe-${app_n}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${app_n}-${take(guid(subscription().id, app_n, resourceGroup().name), 4)}'
        properties: {
          privateLinkServiceId: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${appService.name}'
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    subnet: {
      id: snet_app_vnet_pe_id
    }
  }
}

// App Private DNS Zone Group - A Record
resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = if (!empty(snet_app_vnet_pe_id)) {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurewebsites.net'
        properties: {
          privateDnsZoneId: pdnsz_app_id
        }
      }
    ]
  }
}

module pdnszVnetLinkDeployment 'br:bicephubdev.azurecr.io/bicep/modules/networkprivatednszonesvirtualnetworklinks:b066cd77ae1236f4b0e18c6a2c530aa5518de854' = if (!empty(snet_app_vnet_pe_id) && app_pe_create_virtual_network_link) {
  name: 'pdnsVnetLinkDeployment'
  scope: resourceGroup(pdnsz_app_parsed_id.rg_n)
  params: {
    snet_app_pe_id: split(snet_app_vnet_pe_id, '/subnets/')[0]
    enable_pdnsz_autoregistration: false
    pdnsz_app_id: pdnsz_app_id
    tags: tags
  }
}

// ------------------------------------------------------------------------------------------------
// Link App Insights
// ------------------------------------------------------------------------------------------------
resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = if(!empty(appi_k)) {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appi_k
  }
  dependsOn: [
    appServiceWebSettings
  ]
}

resource appServiceLogSettings 'Microsoft.Web/sites/config@2020-06-01' = if(!empty(appi_k)) {
  parent: appService
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
  dependsOn: [
    appServiceWebSettings
    appServiceAppSettings
  ]
}

resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = if(!empty(appi_k)) {
  parent: appService
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
  dependsOn: [
    appServiceWebSettings
    appServiceAppSettings
    appServiceLogSettings
  ]
}

output app object = appService
output id string = appService.id
