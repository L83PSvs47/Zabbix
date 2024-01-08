function Test-RegistryKey {
    param (
        [Parameter(Mandatory)]
        [string]$Key
    )

    [bool]$result = $false

    if (Get-Item -Path $Key -ErrorAction Ignore) {
        $result = $true
    }

    return $result
}

function Get-PendingReboot {
    [bool]$rebootPending = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    [bool]$packagesPending = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
    [bool]$rebootInProgress = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'

    [bool]$rebootRequired = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    [bool]$postRebootReporting = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting'

    [bool]$currentRebootAttempts = Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts'

    [bool]$joinDomain = Test-RegistryKey -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\JoinDomain'
    [bool]$avoidSpnSet = Test-RegistryKey -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\AvoidSpnSet'

    [bool]$pendingFileRename = $false
    [bool]$pendingRenamUnimportant = $false
    [string[]]$pendingFileRenameOperations = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').PendingFileRenameOperations
    foreach ($pendingFileRenameOperation in $pendingFileRenameOperations) {
        if ($pendingFileRenameOperation.Contains('\Windows\system32\spool')`
                -or $pendingFileRenameOperation.Contains('\Google\Chrome')`
                -or $pendingFileRenameOperation.Contains('\Google\Update')`
                -or $pendingFileRenameOperation.Contains('\Windows\Temp')`
                -or $pendingFileRenameOperation.Contains('\Windows\SystemTemp')`
                -or $pendingFileRenameOperation.Contains('\Microsoft OneDrive')`
                -or $pendingFileRenameOperation.Contains('\Microsoft\Edge\Temp')`
                -or $pendingFileRenameOperation.Contains('\Microsoft\EdgeUpdate')) {
            $pendingRenamUnimportant = $true
        }
        elseif ($pendingFileRenameOperation -ne '') {
            $pendingFileRename = $true
        }
    }

    [bool]$renameComputer = $false
    [string]$oldComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName').ComputerName
    [string]$newComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName').ComputerName
    if ($oldComputerName -ne $newComputerName) {
        $renameComputer = $true
    }

    [bool]$sccm = $false
    try {
        [System.Object]$ccmClientUtilities = ([wmiclass]'root\ccm\ClientSDK:CCM_ClientUtilities').DetermineIfRebootPending()
        if ($ccmClientUtilities.RebootPending -or $ccmClientUtilities.IsHardRebootPending) {
            $sccm = $true
        }
    }
    catch {}

    [bool]$restartRequired = ($rebootPending`
            -or $packagesPending`
            -or $rebootRequired`
            -or $postRebootReporting`
            -or $joinDomain`
            -or $avoidSpnSet`
            -or $sccm`
            -or $renameComputer`
            -or $rebootInProgress`
            -or $currentRebootAttempts)

    return @{
        'RestartRequired'       = $restartRequired
        'RebootPending'         = $rebootPending
        'PackagesPending'       = $packagesPending
        'RebootRequired'        = $rebootRequired
        'PostRebootReporting'   = $postRebootReporting
        'JoinDomain'            = $joinDomain
        'AvoidSpnSet'           = $avoidSpnSet
        'SCCM'                  = $sccm
        'FileRenameOperations'  = $pendingFileRename
        'FileRenameUnimportant' = $pendingRenamUnimportant
        'RenameComputer'        = $renameComputer
        'RebootInProgress'      = $rebootInProgress
        'CurrentRebootAttempts' = $currentRebootAttempts
    }
}