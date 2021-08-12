function Convert-Encoding {
    param (
        [Parameter(Mandatory = $true)]
        [String]$String,

        [Parameter(Mandatory = $true)]
        [string]$From,

        [Parameter(Mandatory = $true)]
        [string]$To
    )

    $encodingFrom = [System.Text.Encoding]::GetEncoding($From)
    $encodingTo = [System.Text.Encoding]::GetEncoding($To)

    return $encodingTo.GetString([System.Text.Encoding]::Convert($encodingFrom, $encodingTo, $encodingTo.GetBytes($String)))
}

function Request-BackupExec {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('jobname', 'libraryname')]
        [string]$Discover
    )

    $result = $null

    try {
        Import-Module BEMCLI -ErrorAction Stop
    }
    catch [System.Exception] {
        return $null
    }

    if ($Discover -eq 'jobname') {
        $jobList = Get-BEJob -Jobtype Backup
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
        $libraryList = Get-BERoboticLibraryDevice
        $result = @(
            foreach ($library in $libraryList) {
                $libraryName = Convert-Encoding -String $library.Name -From cp866 -To utf-8
                @{
                    '{#BE.LIBRARYNAME}' = $libraryName
                }
            }
        )
    }

    return $result
}
