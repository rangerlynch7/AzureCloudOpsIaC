$SubscriptionName="INF NPE"
#$SubscriptionName="CEX LAB"
Enable-AzureRmAlias -Scope CurrentUser
if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account.AccessToken)) {Login-AzureRmAccount}
Select-AzSubscription -SubscriptionName $SubscriptionName
# Enable-AzureRmContextAutoSave

