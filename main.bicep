var unq = '${uniqueString(subscription().id, resourceGroup().id)}'
var storageAccountName = 'stg${unq}'
var storageContainerName = 'lakeroot'
var synapseWorkspaceName = 'syn-${unq}'

resource myStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
  }
}

resource myStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccountName}/default/${storageContainerName}'
  properties: {
    publicAccess: 'Container'
  }
  dependsOn: [
    myStorage
  ]
}

resource mySynapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: resourceGroup().location
  properties: {
    defaultDataLakeStorage: {
      filesystem: storageContainerName
      accountUrl: 'https://${storageAccountName}.dfs.core.windows.net'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
