function Request-DHCPScope {
    [System.Object]$result = $null

    try {
        [System.Object]$scopeList = Get-DhcpServerv4ScopeStatistics

        $result = @(
            foreach ($scope in $scopeList) {
                @{
                    '{#DHCP.SCOPEID}' = [string]$scope.ScopeId
                }
            }
        )
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Request-DHCPScope'
            }
        )
    }

    return $result
}
