param functionAppName string
param location string
param tags object
param hostingPlanId string
param storageAccountName string
param appInsightsConnectionString string
param containerName string
param functionAppRuntimeVersion string
param functionAppPrivateEndpointName string
param functionAppSubnetId string


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}


resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientCertEnabled: true
    serverFarmId: hostingPlanId
    siteConfig: {
      minTlsVersion: '1.3'
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${containerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'python'
        version: functionAppRuntimeVersion
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

/*
@description('Assigns "Storage Blob Data Owner" role to Function App.')
resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, functionAppName, 'StorageBlobDataOwner')
  scope: storageAccount
  properties: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    )
    principalType: 'ServicePrincipal'
  }
}
*/
output name string = functionApp.name
