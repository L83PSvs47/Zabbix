function Request-HyperV {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('vsname', 'vmname')]
        [string]$Discover
    )

    $result = $null

    if ($Discover -eq 'vsname') {
        $result = @(
            $vSwitchList = Get-VMSwitch
            foreach ($vSwitch in $vSwitchList) {
                @{
                    '{#HV.VSNAME}' = $vSwitch.Name
                }
            }
        )
    }

    if ($Discover -eq 'vmname') {
        $result = @(
            $vmList = Get-VM
            foreach ($vm in $vmList) {
                @{
                    '{#HV.VMNAME}' = $vm.VMName
                }
            }
        )
    }

    return $result
}
