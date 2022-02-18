@allowed([
  'default'
  'vNet'
])
@description('Network Isolation Mode')
param networkIsolationMode string = 'default'
param resourceLocation string = resourceGroup().location
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 5)

param workspaceDataLakeAccountName string = 'azwksdatalake${uniqueSuffix}'

param dataLakeSandpitZoneName string = 'sandpit'
param synapseDefaultContainerName string = synapseWorkspaceName

param synapseWorkspaceName string = 'azsynapsewks${uniqueSuffix}'
param synapseSqlAdminUserName string = 'azsynapseadmin'
param synapseSqlAdminPassword string
param synapseManagedRGName string = '${synapseWorkspaceName}-mrg'

//param purviewAccountID string

var storageEnvironmentDNS = environment().suffixes.storage
var dataLakeStorageAccountUrl = 'https://${workspaceDataLakeAccountName}.dfs.${storageEnvironmentDNS}'
var azureRBACStorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role

//Data Lake Storage Account
resource r_workspaceDataLakeAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: workspaceDataLakeAccountName
  location: resourceLocation
  properties: {
    isHnsEnabled: true
    accessTier: 'Hot'
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet') ? 'Deny' : 'Allow'
      bypass: 'None'
      resourceAccessRules: [
        {
          tenantId: subscription().tenantId
          resourceId: r_synapseWorkspace.id
        }
      ]
    }
  }
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

var privateContainerNames = [
  dataLakeSandpitZoneName
  synapseDefaultContainerName
]

resource r_dataLakePrivateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in privateContainerNames: {
  name: '${r_workspaceDataLakeAccount.name}/default/${containerName}'
}]

//Synapse Workspace
resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name:synapseWorkspaceName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    defaultDataLakeStorage:{
      accountUrl: dataLakeStorageAccountUrl
      filesystem: synapseDefaultContainerName
    }
    sqlAdministratorLogin: synapseSqlAdminUserName
    sqlAdministratorLoginPassword: synapseSqlAdminPassword
    //publicNetworkAccess: Post Deployment Script will disable public network access for vNet integrated deployments.
    managedResourceGroupName: synapseManagedRGName
    managedVirtualNetwork: (networkIsolationMode == 'vNet') ? 'default' : ''
    managedVirtualNetworkSettings: (networkIsolationMode == 'vNet')? {
      preventDataExfiltration:true
    }: null
    // purviewConfiguration:{
    //   purviewResourceId: purviewAccountID
    // }
  }

  // resource admin 'administrators' = {
  //   name: 'activeDirectory'
  //   properties: {
  //     administratorType: 'Synapse Administrator'
  //     login: 'tisulliv@microsoft.com'
  //     sid: '36a895ff-8e24-4b03-bf63-574aza9b24ad8f' //timsullivan
  //     tenantId: subscription().tenantId
  //   }
  // }


  //Default Firewall Rules - Allow All Traffic
  resource r_synapseWorkspaceFirewallAllowAll 'firewallRules' = if (networkIsolationMode == 'default'){
    name: 'AllowAllNetworks'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

  //Firewall Allow Azure Sevices
  //Required for Post-Deployment Scripts
  resource r_synapseWorkspaceFirewallAllowAzure 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  //Set Synapse MSI as SQL Admin
  resource r_managedIdentitySqlControlSettings 'managedIdentitySqlControlSettings' = {
    name: 'default'
    properties:{
      grantSqlControlToManagedIdentity:{
        desiredState: 'Enabled'
      }
    }
  }
}

//Synapse Workspace Role Assignment as Blob Data Contributor Role in the Data Lake Storage Account
//https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
resource r_dataLakeRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(r_synapseWorkspace.name, r_workspaceDataLakeAccount.name)
  scope: r_workspaceDataLakeAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: r_synapseWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output workspaceName string = r_synapseWorkspace.name
