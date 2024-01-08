function Get-ADReplication {
    param (
        [Parameter(Mandatory)]
        [string]$Partner
    )

    [System.Object]$result = $null

    try {
        [System.Object]$replicationPartnerMetadata = Get-ADReplicationPartnerMetadata -Target $env:COMPUTERNAME -Filter { Partner -like "*$Partner*" }
        [System.Object]$replicationFailure = Get-ADReplicationFailure -Target $env:COMPUTERNAME -Filter { Partner -like "*$Partner*" }

        $lastReplicationResult = $replicationPartnerMetadata.LastReplicationResult
        $lastReplicationAttempt = $replicationPartnerMetadata.LastReplicationAttempt
        $lastReplicationSuccess = $replicationPartnerMetadata.LastReplicationSuccess
        $consecutiveReplicationFailures = $replicationPartnerMetadata.ConsecutiveReplicationFailures

        $firstFailureTime = $replicationFailure.FirstFailureTime
        $failureType = $replicationFailure.FailureType.value__
        $failureCount = $replicationFailure.FailureCount
        $lastError = $replicationFailure.LastError

        if ($null -eq $firstFailureTime) {
            $firstFailureTime = Get-Date '0001.01.01'
        }

        if ($null -eq $failureType) {
            $failureType = 0
        }

        if ($null -eq $failureCount) {
            $failureCount = 0
        }

        if ($null -eq $lastError) {
            $lastError = 0
        }

        $result = @(
            @{
                'LastError'                      = $lastError
                'FailureType'                    = $failureType
                'FailureCount'                   = $failureCount
                'LastReplicationResult'          = $lastReplicationResult
                'ConsecutiveReplicationFailures' = $consecutiveReplicationFailures
                'FirstFailureTime'               = $firstFailureTime.toString('dd-MM-yyyy HH:mm:ss')
                'LastReplicationAttempt'         = $lastReplicationAttempt.toString('dd-MM-yyyy HH:mm:ss')
                'LastReplicationSuccess'         = $lastReplicationSuccess.toString('dd-MM-yyyy HH:mm:ss')
            }
        )
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Get-ADReplication'
            }
        )
    }

    return $result
}
