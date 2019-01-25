#$SubscriptionName="CEX LAB"
$SubscriptionName="INF NPE"
Select-AzSubscription  -SubscriptionName  $SubscriptionName
Get-AzContext | % SubscriptionName
Enable-AzureRmAlias -Scope CurrentUser

