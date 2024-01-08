#Requires -version 3

param (
    [Parameter(Mandatory)]
    [string]$Action,

    [Parameter()]
    [string]$Value,

    [Parameter()]
    [string]$Key
)

[System.Object]$result = $null

try {
    switch ($Action) {
        'Request-CPU' {
            Import-Module -Name $PSScriptRoot\modules\Request-CPU -ErrorAction SilentlyContinue
            $result = Request-CPU
        }

        'Get-PendingReboot' {
            Import-Module -Name $PSScriptRoot\modules\Get-PendingReboot
            $result = Get-PendingReboot
        }

        'Request-Certificate' {
            Import-Module -Name $PSScriptRoot\modules\Request-Certificate
            $result = Request-Certificate -Valid $Value
        }

        'Get-Certificate' {
            Import-Module -Name $PSScriptRoot\modules\Get-Certificate
            $result = Get-Certificate -Thumbprint $Value
        }

        'Request-ExchangeMailboxDatabase' {
            Import-Module -Name $PSScriptRoot\modules\Request-ExchangeMailboxDatabase
            $result = Request-ExchangeMailboxDatabase -ExchangeVersion $Key
        }

        'Request-BackupExec' {
            Import-Module -Name $PSScriptRoot\modules\Request-BackupExec
            $result = Request-BackupExec -Discover $Value
        }

        'Get-BackupExecJob' {
            Import-Module -Name $PSScriptRoot\modules\Get-BackupExecJob
            $result = Get-BackupExecJob -JobName $Value
        }

        'Get-BackupExecLibrary' {
            Import-Module -Name $PSScriptRoot\modules\Get-BackupExecLibrary
            $result = Get-BackupExecLibrary -LibraryName $Value
        }

        'Request-HyperV' {
            Import-Module -Name $PSScriptRoot\modules\Request-HyperV
            $result = Request-HyperV -Discover $Value
        }

        'Get-HyperV' {
            Import-Module -Name $PSScriptRoot\modules\Get-HyperV
            $result = Get-HyperV -VMName $Value
        }

        'Get-HyperVReplication' {
            Import-Module -Name $PSScriptRoot\modules\Get-HyperVReplication
            $result = Get-HyperVReplication
        }

        'Request-DHCPScope' {
            Import-Module -Name $PSScriptRoot\modules\Request-DHCPScope
            $result = Request-DHCPScope
        }

        'Get-DHCPScopeStatistics' {
            Import-Module -Name $PSScriptRoot\modules\Get-DHCPScopeStatistics
            $result = Get-DHCPScopeStatistics -ScopeId $Value
        }

        'Request-ADReplication' {
            Import-Module -Name $PSScriptRoot\modules\Request-ADReplication
            $result = Request-ADReplication
        }

        'Get-ADReplication' {
            Import-Module -Name $PSScriptRoot\modules\Get-ADReplication
            $result = Get-ADReplication -Partner $Value
        }
        'Get-DataProtectionManager' {
            Import-Module -Name $PSScriptRoot\modules\Get-DataProtectionManager
            $result = Get-DataProtectionManager
        }
        Default {
            $result = @(
                @{
                    'Error' = 'No action for Get-DataForZabbix'
                }
            )
        }
    }
}
catch {
    $result = @(
        @{
            'Error' = 'Error Get-DataForZabbix'
        }
    )
}

ConvertTo-Json -InputObject @($result) | Write-Output
