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


//NEWLY DEFINED PARAMETERS
param functionAppPlanSku string 
var isReserved = true

// App Service Plan
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
    reserved: isReserved // Specifies Linux OS
  }
}


// Function App
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
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
      linuxFxVersion: (isReserved ? 'python|3.9' : 'python|3.9')
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          // This requires Storage Blob Data Contributor to be set later
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2021-09-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2021-09-01').keys[0].value}'
        }
        {
          name: 'CONTAINER_NAME'
          value: 'files-to-process' // Name of the blob container
        }
      ]

    }
  }
}


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
