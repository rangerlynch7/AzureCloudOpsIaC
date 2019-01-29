

$workspaceName="cexlab-databricks2"
$resourceGroupName="cexlab-ce-databricks-rg"
$NetResourceGroupName="lab-network-rg"
$resourceGroupLocation="canadaeast"
$vnetname="lab-cex-caest-vnet02"
$customprivateSubnetName=$privateSubnetName="Databricks-private"
$customPublicSubnetName=$publicSubnetName="Databricks-control"
$pricingTier="trial"

$deployType="databricks"

$Tags=@{ 
	appsn="DAL"
	env="LAB"
}

$templateFilePath="$deployType.json"
$deploymentName="$deployType-$(get-date -f yyyymmdd_HHmm)"

# $nsgName="databricks-tier-lab"
# $nsg=Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $NetResourceGroupName
# $nsgId=$nsg.Id
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $NetResourceGroupName
$customVirtualNetworkId=$vnet.Id

Try {
    Get-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction Stop
    Set-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction Stop -Tag $Tags
} Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -ErrorAction SilentlyContinue -Confirm:$false -Force -Tag $Tags
}
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -workspaceName $workspaceName -pricingTier $pricingTier -customVirtualNetworkId $customVirtualNetworkId -customPublicSubnetName $customPublicSubnetName -customPrivateSubnetName $customPrivateSubnetName -Verbose

# ./deploy.ps1 -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -templateFilePath ./azuredeploy.json -parametersFilePath ./azuredeploy.parameters.json


