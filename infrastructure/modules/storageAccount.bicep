@maxLength(24)
@description('It must be 3-24 chars long, and can contain only lowercase letters and numbers')
param storageAccountName string
param location string
param storageSku string
param tags object
param containerName string
param accessTier string
param storagePrivateEndpointName string
param storageSubnetId string


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction:  'Deny'
      bypass: 'AzureServices'
    }
  }
  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
       deleteRetentionPolicy: {
         enabled: true
         days: 7
       }
    }
    resource blobContainer 'containers' = {
      name: containerName
      properties: {
        publicAccess: 'None'
      }
    }
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

output id string = storageAccount.id
output name string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
