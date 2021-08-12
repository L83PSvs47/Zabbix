function Request-ExchangeMailboxDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(2010, 2013, 2016, 2019)]
        [int]$ExchangeVersion
    )

    switch ($ExchangeVersion) {
        2010 { $snapinName = 'Microsoft.Exchange.Management.PowerShell.E2010' }
        Default { $snapinName = 'Microsoft.Exchange.Management.PowerShell.SnapIn' }
    }

    try {
        Add-PSSnapin -Name $snapinName -ErrorAction Stop
    }
    catch [System.Exception] {
        return $null
    }

    $edbList = Get-MailboxDatabase

    return @(
        foreach ($edb in $edbList) {
            @{
                '{#EDB.NAME}' = $edb.Name
                '{#EDB.PATH}' = $edb.EdbFilePath.PathName
            }
        }
    )
}
