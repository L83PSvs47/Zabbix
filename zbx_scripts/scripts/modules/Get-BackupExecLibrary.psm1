function Get-BackupExecLibrary {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryName
    )

    try {
        Import-Module BEMCLI -ErrorAction Stop
    }
    catch [System.Exception] {
        return $null
    }

    $mediaAvailableSum = $null
    $mediaList = Get-BEMedia

    foreach ($media in $mediaList) {
        if ($media.LocationName -eq $LibraryName) {
            $mediaAvailable = Measure-Object -InputObject $media AvailableCapacityBytes -Sum
            $mediaAvailableSum += $mediaAvailable.Sum
        }
    }

    return @{
        MediaAvailable = $mediaAvailableSum
    }
}
