function Convert-Encoding {
    param (
        [Parameter(Mandatory)]
        [string]$String,

        [Parameter(Mandatory)]
        [string]$From,

        [Parameter(Mandatory)]
        [string]$To
    )

    [string]$result = $null
    $encodingFrom = [System.Text.Encoding]::GetEncoding($From)
    $encodingTo = [System.Text.Encoding]::GetEncoding($To)
    $result = $encodingTo.GetString([System.Text.Encoding]::Convert($encodingFrom, $encodingTo, $encodingTo.GetBytes($String)))

    return $result
}

function Request-BackupExec {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('jobname', 'libraryname')]
        [string]$Discover
    )

    [System.Object]$result = $null

    try {
        Import-Module BEMCLI -ErrorAction Stop

        if ($Discover -eq 'jobname') {
            [System.Object]$jobList = Get-BEJob -Jobtype Backup
            [string]$jobName = $null

            $result = @(
                foreach ($job in $jobList) {
                    $jobName = Convert-Encoding -String $job.Name -From cp866 -To utf-8
                    @{
                        '{#BE.JOBNAME}' = $jobName
                    }
                }
            )
        }

        if ($Discover -eq 'libraryname') {
            [System.Object]$libraryList = Get-BERoboticLibraryDevice
            [string]$libraryName = $null

            $result = @(
                foreach ($library in $libraryList) {
                    $libraryName = Convert-Encoding -String $library.Name -From cp866 -To utf-8
                    @{
                        '{#BE.LIBRARYNAME}' = $libraryName
                    }
                }
            )
        }
    }
    catch [System.Exception] {
        $result = @(
            @{
                'Error' = 'Error Request-BackupExec'
            }
        )
    }

    return $result
}
