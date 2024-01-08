function Get-Certificate {
    param (
        [Parameter(Mandatory)]
        [string]$Thumbprint
    )

    [System.Object]$result = $null

    try {
        [X509Certificate]$certificate = Get-Item -Path Cert:\LocalMachine\My\$Thumbprint -ErrorAction Stop

        [string]$ipPort = ''
        [string]$appID = ''
        [string]$certDNSNameList = ''
        [string]$newLine = [System.Environment]::NewLine

        [string]$bindingList = (& netsh http show sslcert) | Select-Object -Skip 3 | Out-String
        [string[]]$bindingList = $bindingList -split "$newLine$newLine"
        [int]$certDaysToExpire = (New-TimeSpan -End $certificate.NotAfter).Days

        if ($certificate.DnsNameList.Length) {
            [System.Object]$certDNSNames = @()
            $certificate.DnsNameList | ForEach-Object { $certDNSNames += $_.Unicode }
            $certDNSNameList = $certDNSNames -join ', '
        }

        foreach ($binding in $bindingList) {
            if ($binding -ne '') {
                $binding = $binding -replace '  ', '' -split ': '
                $certificateHash = ($binding[2] -split "`n" -split "`r" -replace '[^a-zA-Z0-9]', '')[0]

                if ($certificateHash -eq $Thumbprint) {
                    $ipPort = ($binding[1] -split "`n" -split "`r")[0]
                    $appID = ($binding[3] -split "`n" -split "`r")[0]
                }
            }
        }

        $result = @{
            'DaysToExpire'       = $certDaysToExpire
            'DnsNameList'        = $certDNSNameList
            'FriendlyName'       = [string]$certificate.FriendlyName
            'Issuer'             = [string]$certificate.Issuer
            'KeyLength'          = [int]$certificate.PublicKey.Key.KeySize
            'NotAfter'           = $certificate.NotAfter.ToString()
            'NotBefore'          = $certificate.NotBefore.ToString()
            'SerialNumber'       = [string]$certificate.SerialNumber
            'SignatureAlgorithm' = [string]$certificate.SignatureAlgorithm.FriendlyName
            'Subject'            = [string]$certificate.Subject
            'Thumbprint'         = [string]$certificate.Thumbprint
            'Version'            = [int]$certificate.Version
            'IPPort'             = $ipPort
            'AppID'              = $appID
        }
    }
    catch [System.Exception] {
        $result = @(
            @{
                'Error' = 'Error Get-Certificate'
            }
        )
    }

    return $result
}
