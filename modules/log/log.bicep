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
@description('Log Analytics name')
param name string

resource log 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output id string = log.id
