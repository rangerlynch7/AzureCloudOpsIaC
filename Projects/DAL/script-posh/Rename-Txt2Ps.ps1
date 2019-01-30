$MyInvocation.MyCommand.Source | split-path | set-Location
Get-ChildItem -File -Recurse -Include *ps1.txt | % { Rename-Item -Path $_.PSPath -NewName $_.Name.replace(".ps1.txt",".ps1")}
