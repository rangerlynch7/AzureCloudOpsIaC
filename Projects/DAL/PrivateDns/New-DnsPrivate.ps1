# https://docs.microsoft.com/en-ca/azure/dns/private-dns-overview
# https://docs.microsoft.com/en-ca/azure/dns/private-dns-getstarted-cli
# https://docs.microsoft.com/en-ca/azure/dns/private-dns-getstarted-powershell

$resourceGroupName=$VnetResourceGroupName
Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
} Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue -Confirm:$false -Force
}

$NetworkSecurityGroupId=Get-AzureRmNetworkSecurityGroup | ? Name -eq $nsgName | % Id
if ($null -eq $NetworkSecurityGroupId) { throw "$NetworkSecurityGroupId is null"}

$Subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $Subnet1AddressPrefix -NetworkSecurityGroupId $NetworkSecurityGroupId
$vnet =  New-AzureRmVirtualNetwork `
  -ResourceGroupName $resourceGroupName `
  -Location $Location `
  -Name $vnetName `
  -AddressPrefix $VnetAddressPrefix  `
  -Subnet $Subnet1 

$vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName  -Name $vnetName
Add-AzureRmVirtualNetworkSubnetConfig -Name $Subnet2Name -VirtualNetwork $vnet -AddressPrefix $Subnet2AddressPrefix
Add-AzureRmVirtualNetworkSubnetConfig -Name $Subnet3Name -VirtualNetwork $vnet -AddressPrefix $Subnet3AddressPrefix
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet 

# Remove-AzureRmDnsZone -Name $DnsZoneName -ResourceGroupName $ResourceGroupName

New-AzureRmDnsZone -Name $DnsZoneName -ResourceGroupName $ResourceGroupName `
   -ZoneType Private `
   -RegistrationVirtualNetworkId @($vnet.Id)

# Get-AzureRmDnsZone -ResourceGroupName $ResourceGroupName