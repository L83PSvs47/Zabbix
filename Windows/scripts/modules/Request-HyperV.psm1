function Request-HyperV {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('vsname', 'vmname')]
        [string]$Discover
    )

    [System.Object]$result = $null

    try {
        if ($Discover -eq 'vsname') {
            [System.Object]$vSwitchList = Get-VMSwitch
            $result = @(
                foreach ($vSwitch in $vSwitchList) {
                    @{
                        '{#HV.VSNAME}' = [string]$vSwitch.Name
                    }
                }
            )
        }

        if ($Discover -eq 'vmname') {
            [System.Object]$vmList = Get-VM
            $result = @(
                foreach ($vm in $vmList) {
                    @{
                        '{#HV.VMNAME}' = [string]$vm.VMName
                    }
                }
            )
        }
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Request-HyperV'
            }
        )
    }

    return $result
}
