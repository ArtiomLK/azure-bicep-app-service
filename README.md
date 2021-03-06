# Azure App Service (app)

[![DEV - Deploy Azure Resource](https://github.com/ArtiomLK/azure-bicep-app-service/actions/workflows/dev.orchestrator.yml/badge.svg?branch=main&event=push)](https://github.com/ArtiomLK/azure-bicep-app-service/actions/workflows/dev.orchestrator.yml)

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

## App Service Custom AutoScale

**Duration**: This is amount of time that Autoscale engine will look back for metrics. For example, 10 minutes means that every time autoscale runs, it will query metrics for the past 10 minutes. This allows your metrics to stabilize and avoids reacting to transient spikes. The Storage queue Approximate Message Count and Service Bus Message Count metrics are special in that these metrics are point in time only and have no history. For these metrics, the duration field will be ignored by the Autoscale engine.

**Cool Down**: The amount of time to wait after a scale operation before scaling again. For example, if cooldown is 10 minutes and a scale operation just occurred, Autoscale will not attempt to scale again until after 10 minutes. This is to allow the metrics to stabilize first.

### Scale out

1. CPU Average > 60%
   1. Duration: 5 minutes
   2. Cool Down: 5 minutes
   3. Increase Count by: 1
2. Memory Average > 60%
   1. Duration: 5 minutes
   2. Cool Down: 5 minutes
   3. Increase Count by: 1
3. Http Queue Length Average > 100
   1. Duration: 5 minutes
   2. Cool Down: 5 minutes
   3. Increase Count by: 1

### Scale in

1. CPU Average < 15%
   1. Duration: 15 minutes
   2. Cool Down: 15 minutes
   3. Decrease Count by: 1
2. Memory Average < 25%
   1. Duration: 15 minutes
   2. Cool Down: 15 minutes
   3. Decrease Count by: 1
3. Http Queue Length Average <= 0
   1. Duration: 15 minutes
   2. Cool Down: 15 minutes
   3. Decrease Count by: 1

## Debug

- App Service -> Diagnose and solve problems
- App Insight Profiler
- App Insights Workbooks
- Open the app service console and run `tcpping cname` or `tcpping ip`

   ```bash
   tcpping ##.##.##.###
   tcpping http://contoso.com
   tcpping https://contoso.com
   tcpping contoso.com
   tcpping <app_name>.azurewebsites.net
   ```

```bash
# Generate https calls for appi review
for i in {0..10}
do
  echo "";
  curl -X GET https://<app_name>.azurewebsites.net;
  echo "";
done
```

## Logs

### App Insights

```java (Kusto)
// appi dependencies
// Which dependencies take more than a minute to complete
AppDependencies
| where todouble(DurationMs) >= 60000
```

## Additional Resources

- App Service
- [MS | Docs | App Service pricing][3]
- [MS | Docs | Best practices for Autoscale][4]
- [MS | Docs | Inside the Azure App Service Architecture][11]
- Monitoring
- [MS | Docs | Azure Monitor Logs table reference organized by resource type][5]
- [MS | Docs | Enable diagnostics logging for apps in Azure App Service | Supported log types][2]
- App Insights
- [MS | Docs | Profile production applications in Azure with Application Insights][14]
  - [MS | Docs | Windows Performance Analyzer][9]
- [MS | Docs | Dependency Tracking in Azure Application Insights][12]
- [MS | Docs | Debug snapshots on exceptions in .NET apps][13]
- Debug
- [MS | Docs | Troubleshoot slow app performance issues in Azure App Service][10]
- [MS | blog | How to ping from an Azure App service with TCPPING][7]
- Log
- [MS | Docs | Samples for Kusto Queries][8]
- Build 2022
- [MS | techcommunity | What's New in Azure App Service at Build 2022][6]

[1]: ./examples/examples.bicep
[2]: https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs
[3]: https://azure.microsoft.com/en-us/pricing/details/app-service/windows/
[4]: https://docs.microsoft.com/en-us/azure/azure-monitor/autoscale/autoscale-best-practices
[5]: https://docs.microsoft.com/en-us/azure/azure-monitor/reference/tables/tables-resourcetype
[6]: https://techcommunity.microsoft.com/t5/apps-on-azure-blog/what-s-new-in-azure-app-service-at-build-2022/ba-p/3407584
[7]: https://www.code4it.dev/blog/tcpping-azure-portal
[8]: https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/samples
[9]: https://docs.microsoft.com/en-us/windows-hardware/test/wpt/windows-performance-analyzer
[10]: https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-performance-degradation
[11]: https://docs.microsoft.com/en-us/archive/msdn-magazine/2017/february/azure-inside-the-azure-app-service-architecture
[12]: https://docs.microsoft.com/en-us/azure/azure-monitor/app/asp-net-dependencies
[13]: https://docs.microsoft.com/en-us/azure/azure-monitor/snapshot-debugger/snapshot-debugger
[14]: https://docs.microsoft.com/en-us/azure/azure-monitor/profiler/profiler-overview
