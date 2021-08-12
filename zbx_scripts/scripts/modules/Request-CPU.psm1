<#
    Функция устарела и приведена как пример получения данных скриптом
    Функционал реализован в Zabbix Agent
    Items: Number of CPUs = system.cpu.num
    Discovery: CPU Logical = system.cpu.discovery
    Items prototypes: CPU {#CPU.NUMBER} utilisation = system.cpu.util["{#CPU.NUMBER}"]
#>

function Request-CPU {

    $cpuList = Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_Processor -Filter { Name != '_Total' }

    return @(
        foreach ($cpu in $cpuList) {
            @{
                '{#CPU.NUMBER}' = $cpu.Name
            }
        }
    )
}
