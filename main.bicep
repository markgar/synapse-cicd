var unq = '${uniqueString(subscription().id, resourceGroup().id)}'

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

resource mySynapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: unq
  location: resourceGroup().location 
}
