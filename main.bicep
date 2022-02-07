var unq = '${uniqueString(subscription().id, resourceGroup().id)}'
var storageContainerName = 'lake'

resource myStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: unq
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
  name: '${unq}/default/${storageContainerName}'
  properties: {
    publicAccess: 'Container'
  }
}

resource mySynapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: unq
  location: resourceGroup().location
  properties: {
    defaultDataLakeStorage: {
      resourceId: myStorage.id
      filesystem: storageContainerName
      accountUrl: 'https://${unq}.blob.core.windows.net'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
