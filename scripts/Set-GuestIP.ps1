$vmName = "labdc01" 

$Msvm_VirtualSystemManagementService = Get-WmiObject -Namespace root\virtualization\v2 `
    -Class Msvm_VirtualSystemManagementService 

$Msvm_ComputerSystem = Get-WmiObject -Namespace root\virtualization\v2 `
    -Class Msvm_ComputerSystem -Filter "ElementName='$vmName'" 

$Msvm_VirtualSystemSettingData = ($Msvm_ComputerSystem.GetRelated("Msvm_VirtualSystemSettingData", `
    "Msvm_SettingsDefineState", $null, $null, "SettingData", "ManagedElement", $false, $null) | % {$_})

$Msvm_SyntheticEthernetPortSettingData = $Msvm_VirtualSystemSettingData.GetRelated("Msvm_SyntheticEthernetPortSettingData")

$Msvm_GuestNetworkAdapterConfiguration = ($Msvm_SyntheticEthernetPortSettingData.GetRelated( `
    "Msvm_GuestNetworkAdapterConfiguration", "Msvm_SettingDataComponent", `
    $null, $null, "PartComponent", "GroupComponent", $false, $null) | % {$_})

$Msvm_GuestNetworkAdapterConfiguration.DHCPEnabled = $false
$Msvm_GuestNetworkAdapterConfiguration.IPAddresses = @("192.168.0.105")
$Msvm_GuestNetworkAdapterConfiguration.Subnets = @("255.255.255.0")
$Msvm_GuestNetworkAdapterConfiguration.DefaultGateways = @("192.168.0.1")
#$Msvm_GuestNetworkAdapterConfiguration.DNSServers = @("192.168.1.10", "192.168.1.12")

$Msvm_VirtualSystemManagementService.SetGuestNetworkAdapterConfiguration( `
$Msvm_ComputerSystem.Path, $Msvm_GuestNetworkAdapterConfiguration.GetText(1))