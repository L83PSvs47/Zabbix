function Request-DHCPScope {
    try {
        $scopeList = Get-DhcpServerv4ScopeStatistics
    }
    catch {
        return $null
    }

    return @(
        foreach ($scope in $scopeList) {
            @{
                '{#DHCP.SCOPEID}' = [string]$scope.ScopeId
            }
        }
    )
}
