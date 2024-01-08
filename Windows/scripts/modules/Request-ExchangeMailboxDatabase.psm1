function Request-ExchangeMailboxDatabase {
    param (
        [Parameter(Mandatory)]
        [ValidateSet(2010, 2013, 2016, 2019)]
        [int]$ExchangeVersion
    )

    [string]$snapinName = $null
    [System.Object]$result = $null

    try {
        switch ($ExchangeVersion) {
            2010 {
                $snapinName = 'Microsoft.Exchange.Management.PowerShell.E2010'
            }
            Default {
                $snapinName = 'Microsoft.Exchange.Management.PowerShell.SnapIn'
            }
        }

        Add-PSSnapin -Name $snapinName -ErrorAction Stop

        [System.Object]$edbList = Get-MailboxDatabase

        $result = @(
            foreach ($edb in $edbList) {
                @{
                    '{#EDB.NAME}' = [string]$edb.Name
                    '{#EDB.PATH}' = [string]$edb.EdbFilePath.PathName
                }
            }
        )
    }
    catch [System.Exception] {
        $result = @(
            @{
                'Error' = 'Error Request-ExchangeMailboxDatabase'
            }
        )
    }

    return $result
}
