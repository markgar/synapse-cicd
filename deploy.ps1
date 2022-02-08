$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az deployment group create -g synapse-cicd-1 --template-file ./main.bicep --name $deploymentName