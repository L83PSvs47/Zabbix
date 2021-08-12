function Get-Certificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Thumbprint
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    try {
        $certificate = Get-Item -Path Cert:\LocalMachine\My\$Thumbprint -ErrorAction Stop
    }
    catch [System.Exception] {
        return $null
    }

    try {
        $webBindingList = Get-WebBinding -Protocol https -ErrorAction Stop
    }
    catch [System.Exception] {
        $webBindingList = $null
    }

    $netshBindingList = (& netsh http show sslcert) | select-object -skip 3 | out-string
    $newLine = [System.Environment]::NewLine
    $netshBindingList = $netshBindingList -split "$newLine$newLine"

    $certDaysToExpire = (New-TimeSpan -End $certificate.NotAfter).Days
    $certDNSNameList = ''

    $certDNSNames = @()
    if ($certificate.DnsNameList.Length) {
        foreach ($certDnsName in $certificate.DnsNameList) {
            $certDNSNames += $certDnsName.Unicode
        }
        $certDNSNameList = $certDNSNames -join ', '
    }

    $webBinding = @()
    foreach ($binding in $webBindingList) {
        $certificateHash = $binding.certificateHash
        if ($certificateHash -eq $Thumbprint) {
            $webBinding += $binding.bindingInformation.TrimEnd(':') + ' ' + ($binding.ItemXPath -replace '(?:.*?)name=''([^'']*)(?:.*)', '$1')
        }
    }

    $netshBinding = @()
    foreach ($binding in $netshBindingList) {
        if ($binding -ne '') {
            $binding = $binding -replace '  ', '' -split ': '
            $certificateHash = ($binding[2] -split "`n" -split "`r" -replace '[^a-zA-Z0-9]', '')[0]
            if ($certificateHash -eq $Thumbprint) {
                $netshBinding += ($binding[1] -split "`n" -split "`r")[0].TrimEnd() + ' ' + ($binding[3] -split "`n" -split "`r")[0].TrimEnd()
            }
        }
    }

    return @{
        DaysToExpire       = $certDaysToExpire
        DnsNameList        = $certDNSNameList
        FriendlyName       = $certificate.FriendlyName -replace '[^\p{L}\p{N}/ /*/./_/-]', ''
        Subject            = $certificate.Subject -replace '[^\p{L}\p{N}/ /*/./_/=/,/@/-]', ''
        Issuer             = $certificate.Issuer -replace '[^\p{L}\p{N}/ /*/./_/=/,/@/-]', ''
        KeyLength          = $certificate.PublicKey.Key.KeySize
        NotAfter           = $certificate.NotAfter.ToString()
        NotBefore          = $certificate.NotBefore.ToString()
        SerialNumber       = $certificate.SerialNumber
        SignatureAlgorithm = $certificate.SignatureAlgorithm.FriendlyName
        Thumbprint         = $certificate.Thumbprint
        Version            = $certificate.Version
        WebBinding         = $webBinding
        NetshBinding       = $netshBinding
    }
}
