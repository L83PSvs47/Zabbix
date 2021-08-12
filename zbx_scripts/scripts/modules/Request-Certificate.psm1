function Request-Certificate {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    $certList = Get-ChildItem -Path Cert:\LocalMachine\My\

    return @(
        foreach ($cert in $certList) {
            $certName = $cert.Subject.Split(',')[0].Split('=')[1] -replace '[^\p{L}\p{N}/ /*/./_/-]', ''
            if ($certName -eq '') {
                $certName = $cert.SerialNumber
            }
            @{
                '{#CERT.NAME}'       = $certName
                '{#CERT.THUMBPRINT}' = $cert.Thumbprint
            }
        }
    )
}
