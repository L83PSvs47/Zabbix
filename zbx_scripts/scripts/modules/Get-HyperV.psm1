function Get-HyperV {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VMName
    )

    if ($VMName -eq 'all') {
        $vmList = Get-VM
        $vmsMemoryStartup = 0
        $vmsMemoryAssigned = 0
        $vmsMemoryMinimum = 0
        $vmsMemoryMaximum = 0
        $vmsMemoryDemand = 0
        $vmsHostStateRunning = 0
        $vmsHostStateOff = 0
        $vmsHostStateSaved = 0
        $vmsHostStatePaused = 0
        $vmsHostStateOther = 0
        $vmsClusterStateRunning = 0
        $vmsClusterStateOff = 0
        $vmsClusterStateSaved = 0
        $vmsClusterStatePaused = 0
        $vmsClusterStateOther = 0

        foreach ($vm in $vmList) {
            $vmsMemoryAssigned += $vm.MemoryAssigned
            $vmsMemoryDemand += $vm.MemoryDemand
            $vmsMemoryStartup += $vm.MemoryStartup

            if ($vm.DynamicMemoryEnabled -eq 'True') {
                $vmsMemoryMinimum += $vm.MemoryMinimum
                $vmsMemoryMaximum += $vm.MemoryMaximum
            }
            else {
                $vmsMemoryMinimum += $vm.MemoryStartup
                $vmsMemoryMaximum += $vm.MemoryStartup
            }

            if ($vm.IsClustered) {
                switch ($vm.State) {
                    'Running' { $vmsClusterStateRunning += 1 }
                    'Saved' { $vmsClusterStateSaved += 1 }
                    'Paused' { $vmsClusterStatePaused += 1 }
                    'Off' { $vmsClusterStateOff += 1 }
                    default { $vmsClusterStateOther += 1 }
                }
            }
            else {
                switch ($vm.State) {
                    'Running' { $vmsHostStateRunning += 1 }
                    'Saved' { $vmsHostStateSaved += 1 }
                    'Paused' { $vmsHostStatePaused += 1 }
                    'Off' { $vmsHostStateOff += 1 }
                    default { $vmsHostStateOther += 1 }
                }
            }
        }

        $result = @{
            vmsMemoryStartup       = $vmsMemoryStartup
            vmsMemoryMinimum       = $vmsMemoryMinimum
            vmsMemoryMaximum       = $vmsMemoryMaximum
            vmsMemoryDemand        = $vmsMemoryDemand
            vmsMemoryAssigned      = $vmsMemoryAssigned
            vmsHostStateRunning    = $vmsHostStateRunning
            vmsHostStateSaved      = $vmsHostStateSaved
            vmsHostStatePaused     = $vmsHostStatePaused
            vmsHostStateOff        = $vmsHostStateOff
            vmsHostStateOther      = $vmsHostStateOther
            vmsClusterStateRunning = $vmsClusterStateRunning
            vmsClusterStateSaved   = $vmsClusterStateSaved
            vmsClusterStatePaused  = $vmsClusterStatePaused
            vmsClusterStateOff     = $vmsClusterStateOff
            vmsClusterStateOther   = $vmsClusterStateOther
        }
    }
    else {
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        $vm = Get-VM -VMName $VMName
        $vmOwner = $vm.ComputerName
        $vmAtAnotherNode = 0

        if ($cluster) {
            if (!$vm) {
                $vmOwner = (Get-ClusterGroup -Cluster $cluster.name -Name $VMName).OwnerNode.Name
                $vmAtAnotherNode = 1

                $result = @{
                    vmIsClustered   = 1
                    vmOwner         = $vmOwner
                    vmAtAnotherNode = $vmAtAnotherNode
                }
            }
        }

        if ($vm) {
            # Checkpoint State
            $vmChekpointCount = 0
            if ($vm.ParentSnapshotId) {
                $vmChekpointCount = (Get-VMSnapshot -ComputerName $vm.ComputerName -VMName $vm.VMName).Count
            }

            $vmDisks = Get-VMDisks -VMObject $vm -ChekpointCount $vmChekpointCount

            $vmNetworkAdapters = Get-VMNetworkAdapters -VMObject $vm

            # Because of IntegrationServicesState is string, I've made a dict to map it to int (better for Zabbix):
            $IntegrationServicesState = @{
                'Up to date'      = 0
                'Update required' = 1
                ''                = 2
            }

            $result = @{
                vmAutomaticStartAction           = $vm.AutomaticStartAction
                vmAutomaticStartDelay            = $vm.AutomaticStartDelay
                vmAutomaticStopAction            = $vm.AutomaticStopAction
                vmCPUUsage                       = $vm.CPUUsage
                vmMemoryAssigned                 = $vm.MemoryAssigned
                vmMemoryDemand                   = $vm.MemoryDemand
                vmMemoryStatus                   = $vm.MemoryStatus
                vmNumaNodesCount                 = $vm.NumaNodesCount
                vmNumaSocketCount                = $vm.NumaSocketCount
                vmHeartbeat                      = $vm.Heartbeat
                vmIntegrationServicesState       = $IntegrationServicesState[$vm.IntegrationServicesState]
                vmIntegrationServicesVersion     = [string]$vm.IntegrationServicesVersion
                vmUptime                         = [math]::Round($vm.Uptime.TotalSeconds)
                vmStatus                         = $vm.Status
                vmReplicationHealth              = [int]$vm.ReplicationHealth
                vmReplicationMode                = [int]$vm.ReplicationMode
                vmReplicationState               = [int]$vm.ReplicationState
                vmReplicationFrequencySec        = $vm.ReplicationFrequencySec
                vmReplicationLastReplicationTime = $vm.ReplicationLastReplicationTime
                vmReplicationPrimaryServer       = $vm.ReplicationPrimaryServer
                vmReplicationReplicaServer       = $vm.ReplicationReplicaServer
                vmReplicationRelationshipType    = $vm.ReplicationRelationshipType
                vmCheckpointType                 = $vn.CheckpointType
                vmVersion                        = $vm.Version
                vmNotes                          = $vm.Notes
                vmState                          = [int]$vm.State
                vmDynamicMemoryEnabled           = [int]$vm.DynamicMemoryEnabled
                vmMemoryMaximum                  = $vm.MemoryMaximum
                vmMemoryMinimum                  = $vm.MemoryMinimum
                vmMemoryStartup                  = $vm.MemoryStartup
                vmProcessorCount                 = $vm.ProcessorCount
                vmGeneration                     = $vm.Generation
                vmConfigurationLocation          = $vm.ConfigurationLocation
                vmIsClustered                    = [int]$vm.IsClustered
                vmOwner                          = $vmOwner
                vmAtAnotherNode                  = $vmAtAnotherNode
                vmChekpointCount                 = $vmChekpointCount
                vmAllVhdFileSize                 = $vmAllVhdFileSize
                vmDisks                          = $vmDisks
                vmNetworkAdapters                = $vmNetworkAdapters
            }
        }
    }

    return $result
}

function Get-VMNetworkAdapters {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]$VMObject
    )

    $vmNetAdapterList = $VMObject.NetworkAdapters
    $vmNetworkAdapters = @()

    foreach ($vmNetAdapter in $vmNetAdapterList) {
        $vmNetworkAdapters += @(
            @{
                vmNetAdapterName              = $vmNetAdapter.Name
                vmNetAdapterID                = $vmNetAdapter.Id.Remove(0, 47)
                vmNetAdapterLegacy            = $vmNetAdapter.IsLegacy
                vmNetAdapterIP                = ($vmNetAdapter.IPAddresses -join ', ').ToString()
                vmNetAdapterConnection        = $vmNetAdapter.Connected
                vmNetAdapterSwitchName        = $vmNetAdapter.SwitchName
                vmNetAdapterVlan              = $vmNetAdapter.VlanSetting.AccessVlanId
                vmNetAdapterMacAddress        = $vmNetAdapter.MacAddress
                vmNetAdapterMacAddressDynamic = $vmNetAdapter.DynamicMacAddressEnabled
                vmNetAdapterDhcpGuard         = $vmNetAdapter.DhcpGuard
                vmNetAdapterRouterGuard       = $vmNetAdapter.RouterGuard
                vmNetAdapterPortMirroringMode = $vmNetAdapter.PortMirroringMode
            }
        )
    }

    return $vmNetworkAdapters
}

function Get-VMDisks {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]$VMObject,

        [Parameter(Mandatory = $false)]
        [string]$ChekpointCount
    )

    $vmDisks = $null
    $vmVhd = Get-VHD -VMId $VMObject.VMId  -ErrorAction SilentlyContinue
    $vmHdd = Get-VMHardDiskDrive -VMname $VMObject.VMName
    $vmPTDisks = $vmHdd | Where-Object { $null -ne $_.DiskNumber }

    # Pass-Through Disk
    if ($vmPTDisks) {
        foreach ($vmPTDisk in $vmPTDisks) {
            $vmDisks += @(
                @{
                    vmPTDiskNo             = $vmPTDiskNo
                    vmPTDiskPath           = $vmPTDisk.Path
                    vmPTDiskControllerType = [string]$vmPTDisk.ControllerType
                }
            )
        }
    }

    # Virtual Hard Disk
    if ($null -ne $vmVhd) {
        foreach ($vmDisk in $vmVhd) {
            $vmDiskData = $null
            $vmDiskName = $vmDisk.Path.Split('\')[-1]
            $vmDiskPath = $vmDisk.Path
            $vmDiskType = $vmDisk.VhdType
            $vmDiskMaxSize = $vmDisk.Size
            $vmDiskFileSize = $vmDisk.FileSize
            $vmDiskFragmentation = $vmDisk.FragmentationPercentage
            $vmAllVhdFileSize = $vmDisk.FileSize
            $vmDiskControllerType = ($vmHdd | Where-Object { $_.Path -eq $vmDiskPath }).ControllerType

            # If differencing exist
            if ($vmDisk.ParentPath) {

                # Checkpoint label
                if ($vmDiskPath.EndsWith('.avhdx', 1)) {
                    if ($null -ne $ChekpointCount) {
                        $vmDiskName = 'Checkpoint' + $ChekpointCount
                        $ChekpointCount -= 1
                    }
                }

                $vmDiskData += @(
                    @{
                        vmDiskName           = $vmDiskName
                        vmDiskPath           = $vmDiskPath
                        vmDiskFileSize       = $vmDiskFileSize
                        vmDiskMaxSize        = $vmDiskMaxSize
                        vmDiskType           = [string]$vmDiskType
                        vmDiskControllerType = [string]$vmDiskControllerType
                        vmDiskFragmentation  = $vmDiskFragmentation
                    }
                )
                $parentPath = $vmDisk.ParentPath

                # Differencing disk loop
                Do {
                    $vmDiffDisk = Get-VHD -Path $parentPath
                    $vmDiskPath = $vmDiffDisk.Path
                    $vmDiskName = $vmDiffDisk.Path.Split('\')[-1]
                    $vmDiskType = $vmDiffDisk.VhdType
                    $vmDiskMaxSize = $vmDiffDisk.Size
                    $vmDiskFileSize = $vmDiffDisk.FileSize
                    $vmDiskFragmentation = $vmDiffDisk.FragmentationPercentage
                    $vmAllVhdFileSize = $vmAllVhdFileSize + $vmDiffDisk.FileSize

                    # Checkpoint label
                    if ($vmDiskPath.EndsWith('.avhdx', 1)) {
                        if ($null -ne $ChekpointCount) {
                            $vmDiskName = 'Checkpoint' + $ChekpointCount
                            $ChekpointCount -= 1
                        }
                    }

                    $vmDiskData += @(
                        @{
                            vmDiskName           = $vmDiskName
                            vmDiskPath           = $vmDiskPath
                            vmDiskFileSize       = $vmDiskFileSize
                            vmDiskMaxSize        = $vmDiskMaxSize
                            vmDiskType           = [string]$vmDiskType
                            vmDiskControllerType = [string]$vmDiskControllerType
                            vmDiskFragmentation  = $vmDiskFragmentation
                        }
                    )
                    $parentPath = $vmDiffDisk.ParentPath
                }
                Until (!$parentPath)
            }
            else {
                $vmDiskData += @(
                    @{
                        vmDiskName           = $vmDiskName
                        vmDiskPath           = $vmDiskPath
                        vmDiskFileSize       = $vmDiskFileSize
                        vmDiskMaxSize        = $vmDiskMaxSize
                        vmDiskType           = [string]$vmDiskType
                        vmDiskControllerType = [string]$vmDiskControllerType
                        vmDiskFragmentation  = $vmDiskFragmentation
                    }
                )
            }

            $vmDisks += $vmDiskData
        }
    }

    return $vmDisks
}