function Get-DataProtectionManager {
    [System.Object]$result = $null

    try {
        Import-Module DataProtectionManager -ErrorAction Stop

        [System.Object]$alerts = Get-DPMAlert -DPMServerName $env:COMPUTERNAME -WarningAction SilentlyContinue

        [int]$status = 0
        [int]$warnings = ($alerts | Where-Object { $_.Severity -eq 'Warning' }).count
        [int]$errors = ($alerts | Where-Object { $_.Severity -eq 'Error' }).count

        if ($warnings -ne 0) {
            $status = $status -bor  1
        }

        if ($errors -ne 0) {
            $status = $status -bor 2
        }

        $result = @{
            'Status'   = $status
            'Warnings' = $warnings
            'Errors'   = $errors
        }
    }
    catch {
        $result = @(
            @{
                'Error' = 'Error Get-DataProtectionManager'
            }
        )
    }

    return $result
}
