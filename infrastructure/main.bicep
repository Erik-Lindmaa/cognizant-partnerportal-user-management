param projectName string
param environment string
param instance string
param storageSku string
param owner string
param costCenter string
@allowed(['3.10','3.11', '7.4', '8.0', '10', '11', '17', '20'])
param functionAppRuntimeVersion string
@minLength(1)
@description('Primary location for all resources')
@allowed(['eastasia', 'swedencentral'])
param location string
@allowed([
  'Cool'
  'Hot'
  'Premium'
])
param accessTier string

// Used for coherent resource name creation
var suffix = '-${projectName}-${environment}-${instance}'

// Tags all resources with owner and costCenter values
var tags = {
  Owner: owner
  CostCenter: costCenter
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccountModule'
  params: {
    location: location
    tags: tags
    storageSku: storageSku
    storageAccountName: 'st${projectName}${environment}${instance}'
    containerName: 'app-package${suffix}'
    accessTier: accessTier
    storagePrivateEndpointName: 'pe-st${projectName}${environment}${instance}'
    storageSubnetId: '/subscriptions/3efbebad-243d-4156-ae81-4203f7fdcbe2/resourceGroups/rg-spoke-AppInte-nonprod-001-nonprod-003-az03/providers/Microsoft.Network/virtualNetworks/vnet-AppInte-nonprod-001-003-az03/subnets/snet-0102'
  }
}

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsModule'
  params: {
    name: 'logan${suffix}'
    location: location
    tags: tags
  }
}

module applicationInsights 'modules/appInsights.bicep' = {
  name: 'applicationInsightsModule'
  params: {
    location: location
    tags: tags
    appInsightsName: 'appinsights${suffix}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanModule'
  params: {
    location: location
    tags: tags
    appServicePlanName: 'azfunpl${suffix}'
  }
}

// Azure Functions Flex Consumption
module functionApp 'modules/functionApp.bicep' = {
  name: 'functionAppModule'
  params: {
    location: location
    tags: tags
    appInsightsConnectionString: applicationInsights.outputs.connectionString
    storageAccountName: storageAccount.outputs.name
    functionAppName: 'func${suffix}'
    hostingPlanId: appServicePlan.outputs.id
    containerName: 'app-package${suffix}'
    functionAppRuntimeVersion: functionAppRuntimeVersion
    functionAppPrivateEndpointName: 'pe-func${suffix}'
    functionAppSubnetId: '/subscriptions/3efbebad-243d-4156-ae81-4203f7fdcbe2/resourceGroups/rg-spoke-AppInte-nonprod-001-nonprod-003-az03/providers/Microsoft.Network/virtualNetworks/vnet-AppInte-nonprod-001-003-az03/subnets/snet-0102'
  }
}

output functionAppName string = functionApp.outputs.name
