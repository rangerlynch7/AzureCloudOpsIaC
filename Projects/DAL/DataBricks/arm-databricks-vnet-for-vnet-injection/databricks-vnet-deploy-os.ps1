$nsgName=$resourceGroupName="rg-db2"
$resourceGroupLocation="canadacentral"
$vnetName="databricks-vnet"
$privateSubnetName="private-subnet"
$publicSubnetName="public-subnet"
$vnetCidr="10.179.0.0/16"
$privateSubnetCidr="10.179.0.0/18"
$publicSubnetCidr="10.179.64.0/18"

$context=get-azurermcontext
$subscriptionId=$context.Subscription.Id
$deploymentName=$(get-date -f yyyymmdd_HHmm)
$templateFilePath="./azuredeploy.json"
$parametersFilePath="./azuredeploy.parameters.json"

$nsg=Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ResourceGroupName
$nsgId=$nsg.Id

# Get-AzureRmVirtualNetwork -Name 
# existingVNETId

Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction Stop
} Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction SilentlyContinue -Confirm:$false -Force
}

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -nsgId $nsgId -vnetName $vnetName -privateSubnetName $privateSubnetName -publicSubnetName $publicSubnetName -vnetCidr $vnetCidr -privateSubnetCidr $privateSubnetCidr -publicSubnetCidr $publicSubnetCidr -verbose

# ./deploy.ps1 -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -templateFilePath ./azuredeploy.json -parametersFilePath ./azuredeploy.parameters.json

