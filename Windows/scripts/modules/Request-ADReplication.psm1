function Request-ADReplication {

    [System.Object]$result = $null

    try {
        [System.Object]$replicationPartners = (Get-ADReplicationPartnerMetadata -Target $env:COMPUTERNAME).Partner
        $result = @(
            foreach ($replicationPartner in $replicationPartners) {
                @{
                    '{#REPLICATION.PARTNER}' = [regex]::split($replicationPartner, ',CN=')[1]
                }
            }
        )
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Request-ADReplication'
            }
        )
    }

    return $result
}
