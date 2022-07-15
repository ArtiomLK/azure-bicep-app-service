// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
@description('Az Resources tags')
param tags object = {}

@description('Az Resources deployment location. E.G. eastus2 | eastus2,centralus | eastus,westus,centralus')
param location string

// ------------------------------------------------------------------------------------------------
// Log Analytics Workspace Parameters
// ------------------------------------------------------------------------------------------------
@description('Application Insights name')
param name string

@description('Log analytics Workspace ID')
param log_id string

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'string'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: log_id
  }
}

output id string = appi.id
