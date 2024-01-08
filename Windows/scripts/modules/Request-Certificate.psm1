function Request-Certificate {
    param (
        [Parameter()]
        [int]$Valid = 0
    )

    [System.Object]$result = $null

    try {
        [System.Object]$certList = Get-ChildItem -Path Cert:\LocalMachine\My\

        $result = @(
            foreach ($cert in $certList) {
                if (([datetime]$cert.NotAfter - [datetime]$cert.NotBefore).Days -gt $Valid) {
                    [string]$certName = $cert.Subject.Split(',')[0].Split('=')[1]
                    if ($null -eq $certName) {
                        $certName = $cert.SerialNumber
                    }
                    @{
                        '{#CERT.NAME}'       = $certName
                        '{#CERT.THUMBPRINT}' = [string]$cert.Thumbprint
                    }
                }
            }
        )
    }
    catch {
        $result = @(
            @{
                'Error' = 'Request-Certificate'
            }
        )
    }

    return $result
}
