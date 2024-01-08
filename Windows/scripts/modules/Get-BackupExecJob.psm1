function Get-BackupExecJob {
    param (
        [Parameter(Mandatory)]
        [string]$JobName
    )

    [System.Object]$result = $null

    try {
        Import-Module BEMCLI -ErrorAction Stop

        $job = Get-BEJob -Name $JobName
        $jobHistory = Get-BEJobHistory -Name $JobName -JobType 'Backup' | Select-Object -Last 1
        $date = Get-Date -Date '01/01/1970'

        $jobStatus = $jobHistory.JobStatus`
            -replace 'Error', '0'`
            -replace 'Failed', '0'`
            -replace 'Warning', '1'`
            -replace 'SucceededWithExceptions', '2'`
            -replace 'Succeeded', '2'`
            -replace 'None', '2'`
            -replace 'idle', '3'`
            -replace 'Canceled', '4'`
            -replace 'Missed', '5'`
            -replace 'Active', '6'

        $jobType = $job.TaskType`
            -replace 'Full', '0'`
            -replace 'Differential', '1'`
            -replace 'Incremental', '2'

        $jobStartTime = $jobHistory.StartTime
        $jobUnixStartTime = (New-TimeSpan -Start $date -End $jobStartTime).TotalSeconds - 10800 # корректировка временной зоны на 10800 секунд (3 часа)

        $jobEndTime = $jobHistory.EndTime
        $jobUnixEndTime = (New-TimeSpan -Start $date -End $jobEndTime).TotalSeconds - 10800 # корректировка временной зоны на 10800 секунд (3 часа)

        $result = @{
            'JobStatus'        = $jobStatus
            'JobType'          = $jobType
            'JobUnixStartTime' = $jobUnixStartTime
            'JobUnixEndTime'   = $jobUnixEndTime
        }
    }
    catch [System.Exception] {
        $result = @(
            @{
                'Error' = 'Error Get-BackupExecJob'
            }
        )
    }

    return $result
}
