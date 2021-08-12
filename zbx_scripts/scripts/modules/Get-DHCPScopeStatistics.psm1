function Get-DHCPScopeStatistics {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScopeId
    )

    try {
        $scopeStatistics = Get-DhcpServerv4ScopeStatistics -ScopeId $ScopeId
    }
    catch {
        return $null
    }

    return @{
        Free            = $scopeStatistics.Free
        InUse           = $scopeStatistics.InUse
        PercentageInUse = [System.Math]::Round($scopeStatistics.PercentageInUse)
        Reserved        = $scopeStatistics.Reserved
        Pending         = $scopeStatistics.Pending
    }
}
