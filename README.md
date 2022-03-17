# Azure App Service

## Instructions

### Parameter Values

| Name                               | Description                                                                                          | Value                         | Examples                                                                                                                                               |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| tags                               | Az Resources tags                                                                                    | object                        | `{ key: value }`                                                                                                                                       |
| location                           | Az Resources deployment location. To get Az regions run `az account list-locations -o table`         | string [default: rg location] | `eastus` \| `centralus` \| `westus` \| `westus2` \| `southcentralus`                                                                                   |
| app_names                          | App Service Names separated by commas. For example:                                                  | string [required]             | `applicationA` \| `applicationA,applicationB` \| `applicationA,applicationB,applicationC`                                                              |
| plan_id                            | App Service Plan resource ID                                                                         | string [required]             | `/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Web/serverFarms/plan-name`                             |
| app_enable_https_only              | Enable only HTTPS traffic through App Service                                                        | bool [default: `false`]       | `false` \| `true`                                                                                                                                      |
| app_min_tls_v                      | Minimum TLS Version allowed                                                                          | string [default: `1.2`]       | `1.0` \| `1.1` \| `1.2`                                                                                                                                |
| snet_plan_vnet_integration_id      | Enable app Virtual Network Integration by providing a subnet ID                                      | string                        | `/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Network/virtualNetworks/vnet-name/subnets/snet-name`   |
| snet_app_vnet_pe_id                | subnet ID to Enable App Private Endpoints Connections                                                | string                        | `/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Network/virtualNetworks/vnet-name/subnets/snet-name`   |
| app_pe_create_virtual_network_link | Create a Private DNS Zone link to the Private Endpoint Vnet. If the link exists the deployment fails | bool [default: `false`]       | `false` \| `true`                                                                                                                                      |
| pdnsz_app_id                       | App Service Private DNS Zone Resource ID where the A records will be written                         | string                        | `/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net` |

### Conditional Parameter Values

- Deploying App Vnet Integration requires:
  - snet_plan_vnet_integration_id
- Deploying App Service Private Endpoint integration requires:
  - snet_app_vnet_pe_id
  - app_pe_create_virtual_network_link (if the pdnsz to vnet link does not exists set this to true, otherwise set it to false)
  - pdnsz_app_id

### [Reference Examples][1]

### Locally test Azure Bicep Modules

```bash
# Create an Azure Resource Group
az group create \
--name 'rg-azure-bicep-app-service' \
--location 'eastus2' \
--tags project=bicephub env=dev

# Deploy Sample Modules
az deployment group create \
--resource-group 'rg-azure-bicep-app-service' \
--mode Complete \
--template-file examples/examples.bicep
```

[1]: ./examples/examples.bicep
