@description('Name of the Function App')
param functionAppName string

@description('Name of the app service plan')
param appServicePlanName string

@description('Subnet ID for the function app integration')
param functionAppSubnetId string

@description('Region for the resources')
param location string

@description('Name of the function app private endpoint')
param functionAppPrivateEndpointName string

@description('Name of the storage account')
param storageAccountName string

var isReserved = true
param functionAppPlanSku string 

// Reference the existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: functionAppPlanSku
    tier: 'ElasticPremium'
    size: functionAppPlanSku
    family: 'EP'
  }
  kind: 'elastic'
  properties: { 
    maximumElasticWorkerCount: 20
    reserved: isReserved
  } 
}

resource functionApp 'Microsoft.Web/sites@2021-01-01' = {
  name: functionAppName
  location: location
  kind: (isReserved ? 'functionapp,linux' : 'functionapp')
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    reserved: isReserved
    virtualNetworkSubnetId: functionAppSubnetId
    siteConfig: {
      vnetRouteAllEnabled: true
      functionsRuntimeScaleMonitoringEnabled: true
      linuxFxVersion: (isReserved ? 'PYTHON|3.9': null )
        appSettings: [
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net'
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'python'
          }
          {
            name: 'WEBSITE_CONTENTOVERVNET'
            value: '1'
          }
        ]
      }
      
    }
  }

resource functionAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: functionAppPrivateEndpointName
  location: location
  dependsOn: [
    functionApp
  ]
  properties: {
    subnet: {
      id: functionAppSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${functionAppName}-connection'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: ['sites']
        }
      }
    ]
  }
}
