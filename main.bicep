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
@description('App Service Names separated by commas. For example: applicationA | applicationA,applicationB | applicationA,applicationB,applicationC')
param app_names string
var app_names_parsed = split(app_names, ',')

@description('App Service Plan resource ID')
param plan_id string

@description('Enable only HTTPS traffic through App Service')
param app_enable_https_only bool = false

@description('App Service Runtime Stack Type.')
param runtime_stack_n string = 'node'
@description('App Service Runtime Stack Version.')
param runtime_stack_v string = '~16'

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
  siteConfig: {
    minTlsVersion: app_min_tls_v
  }
 }

var app_properties_w_vnet_integration = union(app_properties, {
  virtualNetworkSubnetId: snet_plan_vnet_integration_id
})

// ------------------------------------------------------------------------------------------------
// Deploy Azure Resources
// ------------------------------------------------------------------------------------------------
resource appService 'Microsoft.Web/sites@2021-03-01' = [for i in range(0, length(app_names_parsed)): {
  name: app_names_parsed[i]
  location: location
  properties: empty(snet_plan_vnet_integration_id) ? app_properties : app_properties_w_vnet_integration
  tags: tags
}]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = [for i in range(0, length(app_names_parsed)): if (!empty(snet_app_vnet_pe_id)) {
  tags: tags
  name: 'pe-${app_names_parsed[i]}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${app_names_parsed[i]}-${take(guid(subscription().id, app_names_parsed[i], resourceGroup().name), 4)}'
        properties: {
          privateLinkServiceId: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${appService[i].name}'
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
  dependsOn: [
    appService
  ]
}]

// App Private DNS Zone Group - A Record
resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = [for i in range(0, length(app_names_parsed)): if (!empty(snet_app_vnet_pe_id)) {
  name: '${privateEndpoint[i].name}/default'
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
  dependsOn: [
    privateEndpoint
  ]
}]

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

output appServices array = [for (name, i) in app_names_parsed: {
  id: appService[i].id
  app_n: appService[i].name
  app_fqdn: '${appService[i].name}.azurewebsites.net'
}]
