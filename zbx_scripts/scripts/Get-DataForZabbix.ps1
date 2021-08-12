#Requires -version 3
param (
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Value,

    [Parameter(Mandatory = $false)]
    [string]$Key
)

switch ($Action) {
    'Request-CPU' {
        Import-Module -Name $PSScriptRoot\modules\Request-CPU
        $result = Request-CPU
    }

    'Get-PendingReboot' {
        Import-Module -Name $PSScriptRoot\modules\Get-PendingReboot
        $result = Get-PendingReboot
    }

    'Request-Certificate' {
        Import-Module -Name $PSScriptRoot\modules\Request-Certificate
        $result = Request-Certificate
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

    'Request-DHCPScope' {
        Import-Module -Name $PSScriptRoot\modules\Request-DHCPScope
        $result = Request-DHCPScope
    }

    'Get-DHCPScopeStatistics' {
        Import-Module -Name $PSScriptRoot\modules\Get-DHCPScopeStatistics
        $result = Get-DHCPScopeStatistics -ScopeId $Value
    }
}

$result | ConvertTo-Json -Compress | Write-Output
