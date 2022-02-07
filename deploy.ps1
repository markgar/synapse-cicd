$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az deployment group create -g synapse-cicd --location eastus --template-file ./main.bicep --name $deploymentName