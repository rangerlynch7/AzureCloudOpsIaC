$workspaceName=$nsgName=$resourceGroupName="rg-db2"
$resourceGroupLocation="canadacentral"
$vnetName="databricks-vnet"
$customprivateSubnetName=$privateSubnetName="private-subnet"
$customPublicSubnetName=$publicSubnetName="public-subnet"
$vnetCidr="10.179.0.0/16"
$privateSubnetCidr="10.179.0.0/18"
$publicSubnetCidr="10.179.64.0/18"
$pricingTier="trial"

$context=get-azurermcontext
$subscriptionId=$context.Subscription.Id
$deploymentName=$(get-date -f yyyymmdd_HHmm)
$templateFilePath="./azuredeploy.json"
$parametersFilePath="./azuredeploy.parameters.json"

$nsg=Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ResourceGroupName
$nsgId=$nsg.Id
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName
$customVirtualNetworkId=$vnet.Id

Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction Stop
} Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction SilentlyContinue -Confirm:$false -Force
}
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -workspaceName $workspaceName -pricingTier $pricingTier -customVirtualNetworkId $customVirtualNetworkId -customPublicSubnetName $customPublicSubnetName -customPrivateSubnetName $customPrivateSubnetName -Verbose

# ./deploy.ps1 -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -templateFilePath ./azuredeploy.json -parametersFilePath ./azuredeploy.parameters.json

