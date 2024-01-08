function Get-BackupExecLibrary {
    param (
        [Parameter(Mandatory)]
        [string]$LibraryName
    )

    [System.Object]$result = $null

    try {
        Import-Module BEMCLI -ErrorAction Stop

        $mediaAvailableSum = $null
        $mediaList = Get-BEMedia

        foreach ($media in $mediaList) {
            if ($media.LocationName -eq $LibraryName) {
                $mediaAvailable = Measure-Object -InputObject $media AvailableCapacityBytes -Sum
                $mediaAvailableSum += $mediaAvailable.Sum
            }
        }

        $result = @{
            'MediaAvailable' = $mediaAvailableSum
        }
    }
    catch [System.Exception] {
        $result = @(
            @{
                'Error' = 'Error Get-BackupExecLibrary'
            }
        )
    }

    return $result
}
