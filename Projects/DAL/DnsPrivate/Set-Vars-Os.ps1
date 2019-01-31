# $HdiLoginPassword=""
# $objectId=""
# $HdiSshPassword=""
# $tenantId=""""
$Context=Get-AzureRmContext
$locationcode="cc"
$environment="n" # l lab, n nonprod, p prod
Switch ($locationcode) {
	"cc" { $location="canadacentral" }
	"ce" { $location="canadaeast" }
}

# NETWORK
$resourceGroupNameVnet="$environment.$locationcode.network"
$DnsZoneName="$environment.$locationcode.az.osrg.local"
$Subnet1AddressPrefix="10.2.0.0/24"
$Subnet1Name="kafka"
$Subnet2AddressPrefix="10.2.1.0/24"
$Subnet2Name="subnet2"
$Subnet3AddressPrefix="10.2.2.0/24"
$Subnet3Name="subnet3"
$vnetAddressPrefix="10.2.0.0/16"
$vnetName="rg-vnet0" 
