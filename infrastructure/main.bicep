@description('Name of the storage account')
param storageAccountName string

@description('Name of the Function App')
param functionAppName string

@description('Name of the app service plan')
param appServicePlanName string

@description('Subnet ID for the storage private endpoint')
param storageSubnetId string

@description('Subnet ID for the function app integration')
param functionAppSubnetId string

@description('Region for the resources')
param location string = resourceGroup().location

@description('Name of the storage private endpoint')
param storagePrivateEndpointName string


// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: storageSubnetId
        }
      ]
    }
  }
}

// Storage Private Endpoint
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: storagePrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: storageSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}


// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
      ]
      vnetRouteAllEnabled: true
    }
    virtualNetworkSubnetId: functionAppSubnetId
  }
}

// Outputs
output storageAccountId string = storageAccount.id
output functionAppId string = functionApp.id
output appServicePlanId string = appServicePlan.id
