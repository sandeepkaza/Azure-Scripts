# Connect to Azure
Connect-AzAccount

# === CONFIGURATION ===
# Define subscription(s) explicitly (can be one or many)
$targetSubscriptions = @(
    "1659e9aa-05a3-4abe-afbd-5fd9b6712fae"  # Subscription ID
    # "Another-Subscription-ID"            # (Optional) add more if needed
)

# Define region explicitly
$targetLocation = "SouthCentralUS"   # Example: eastus2, westus, centralus
# ======================

# Create array for inventory
$vmInventory = @()

foreach ($subId in $targetSubscriptions) {
    Set-AzContext -SubscriptionId $subId | Out-Null
    $sub = Get-AzSubscription -SubscriptionId $subId

    # Get VMs in the target region (include status info)
    $vms = Get-AzVM -Status | Where-Object { $_.Location -eq $targetLocation }

    foreach ($vm in $vms) {
        # Collect networking info
        $privateIps = @()
        $publicIps  = @()

        foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
            $nicId   = $nicRef.Id
            $nicName = ($nicId -split "/")[-1]
            $rgName  = ($nicId -split "/")[4]
            $nic     = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName

            foreach ($ipconfig in $nic.IpConfigurations) {
                if ($ipconfig.PrivateIpAddress) { $privateIps += $ipconfig.PrivateIpAddress }
                if ($ipconfig.PublicIpAddress -and $ipconfig.PublicIpAddress.Id) {
                    $pubIpName = ($ipconfig.PublicIpAddress.Id -split "/")[-1]
                    $pubIp = Get-AzPublicIpAddress -Name $pubIpName -ResourceGroupName $rgName
                    if ($pubIp -and $pubIp.IpAddress) { $publicIps += $pubIp.IpAddress }
                }
            }
        }

        # Add to inventory
        $vmInventory += [PSCustomObject]@{
            Subscription   = $sub.Name
            SubscriptionId = $subId
            ResourceGroup  = $vm.ResourceGroupName
            VMName         = $vm.Name
            Location       = $vm.Location
            Size           = $vm.HardwareProfile.VmSize
            OSType         = $vm.StorageProfile.OsDisk.OsType
            PowerState     = $vm.PowerState   # <-- includes Running, Stopped, Deallocated
            PrivateIP      = ($privateIps -join ", ")
            PublicIP       = ($publicIps -join ", ")
        }
    }
}

# Export to CSV
$exportPath = "C:\Temp\Azure_VM_Inventory_$($targetLocation).csv"
$vmInventory | Export-Csv -Path $exportPath -NoTypeInformation -Force
Write-Host "Inventory exported to $exportPath ($($vmInventory.Count) records)"
