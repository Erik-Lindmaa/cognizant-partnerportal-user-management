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
param location string

@description('Name of the storage private endpoint')
param storagePrivateEndpointName string

@description('Name of the function app private endpoint')
param functionAppPrivateEndpointName string



// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
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
          id: storageSubnetId // Allow access from this specific subnet
        }
      ]
    }
  }
}

// Blob Service Resource
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

// Blob Container Resource
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'my-deployment-container'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}



// Storage Private Endpoint
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
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
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true // Specifies Linux OS
  }
}


// Function App
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          // This requires Storage Blob Data Contributor to be set later
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE' // Run function app from zip file
          value: '1'
        }
        {
          name: 'CONTAINER_NAME'
          value: 'files-to-process' // Name of the blob container
        }
      ]

    }
    virtualNetworkSubnetId: functionAppSubnetId
    functionAppConfig: {
      runtime: {
        name: 'python' // Runtime language
        version: '3.11' // Runtime version
      }
      deployment: {
        storage: {
          type: 'blobContainer' // Source deployment from a blob container
          value: '${storageAccount.properties.primaryEndpoints.blob}my-deployment-container'
          authentication: {
            type: 'SystemAssignedIdentity' // Managed identity authentication
          }
        }
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 100
      }
    }
  }
}

// Function App Private Endpoint
resource functionAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: functionAppPrivateEndpointName
  location: location
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


// Outputs
output storageAccountId string = storageAccount.id
output functionAppId string = functionApp.id
output appServicePlanId string = appServicePlan.id
