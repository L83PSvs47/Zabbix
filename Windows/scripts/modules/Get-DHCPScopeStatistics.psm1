function Get-DHCPScopeStatistics {
    param (
        [Parameter(Mandatory)]
        [string]$ScopeId
    )

    [System.Object]$result = $null

    try {
        [ciminstance]$scopeStatistics = Get-DhcpServerv4ScopeStatistics -ScopeId $ScopeId

        $result = @{
            'Free'            = [uint32]$scopeStatistics.Free
            'InUse'           = [uint32]$scopeStatistics.InUse
            'PercentageInUse' = [System.Math]::Round($scopeStatistics.PercentageInUse)
            'Reserved'        = [uint32]$scopeStatistics.Reserved
            'Pending'         = [uint32]$scopeStatistics.Pending
        }
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Get-DHCPScopeStatistics'
            }
        )
    }

    return $result
}
