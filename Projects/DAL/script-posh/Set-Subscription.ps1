#$SubscriptionName="CEX LAB"
$SubscriptionName="INF NPE"
Enable-AzureRmAlias -Scope CurrentUser
Select-AzSubscription  -SubscriptionName  $SubscriptionName
Get-AzContext | % SubscriptionName


