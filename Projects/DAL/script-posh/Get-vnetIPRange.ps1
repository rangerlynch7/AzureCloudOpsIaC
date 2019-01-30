$Subscriptions=Get-AzureRmSubscription
$Subscription=$Subscriptions[0]
foreach ($Subscription in $Subscriptions) {
	Select-AzureRmSubscription -Subscription $Subscription.Id
	Get-AzureRmVirtualNetwork -WarningAction SilentlyContinue | % {write-host $Subscription.Name $_.Name ($_.AddressSpace.AddressPrefixes -join ",")}
}