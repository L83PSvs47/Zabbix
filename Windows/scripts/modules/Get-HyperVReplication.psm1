
function Get-HyperVReplication {
    [System.Object]$result = $null

    try {
        [System.Object]$vmReplication = Get-VMReplication

        [int]$vmReplicationCritical = 0
        [int]$vmReplicationWarning = 0
        [int]$vmReplicationNormal = 0

        if ($vmReplication) {
            $vmReplicationCritical = if ($vmReplication.Health -eq 'Critical') {
                ($vmReplication.Health -eq 'Critical').Count
            }

            $vmReplicationWarning = if ($vmReplication.Health -eq 'Warning') {
                ($vmReplication.Health -eq 'Warning').Count
            }

            $vmReplicationNormal = if ($vmReplication.Health -eq 'Normal') {
                ($vmReplication.Health -eq 'Normal').Count
            }
        }

        $result = @{
            'ReplicationCritical'      = $vmReplicationCritical
            'ReplicationWarning'       = $vmReplicationWarning
            'ReplicationNormal'        = $vmReplicationNormal
        }
    }
    catch {
        $result = @(
            @{
                'Error' = 'Get-HyperVReplication'
            }
        )
    }

    return $result
}
