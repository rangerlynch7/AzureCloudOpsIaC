$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$scriptDir | Set-Location

$CsvFile="../Data/dal-params.csv"
$Column="INF NPE" 
. ../script-posh/Import-Csv2Vars.ps1 -CsvFile $CsvFile -Column $Column
<#
code ../script-posh/Import-Csv2Vars.ps1
#>