$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az group create -n e2e-4 --location eastus
az deployment group create -g e2e-4 --template-file ./accel/AzureAnalyticsE2E.bicep --parameters "synapseSqlAdminPassword=!@#123qweasd" --name $deploymentName
