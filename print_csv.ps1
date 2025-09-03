$rows = Import-Csv 'C:\Temp\Azure_VM_Inventory.csv'
foreach ($r in $rows) {
    $r | Format-List Subscription,ResourceGroup,VMName,PowerState,RawStatusCodes,PrivateIP,PublicIP -Force
    Write-Host '---'
}
