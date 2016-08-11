﻿# Toggle regions: Ctrl + M

#region Demo setup
Write-Warning 'This is a demo script which should be run line by line or sections at a time, stopping script execution'

break

<#

    Author:      Jan Egil Ring
    Name:        Azure Automation DSC - bootstrap.ps1
    Description: This demo script is part of the video presentation 
                 Automatically Configure Your Machines Using Azure Automation DSC at Initial Boot-up
                 
#>

#region Variables

# Template VHDX generated by installing a new VM using an ISO-file, installing latest updates and running sysprep (%windir%\system32\sysprep\sysprep.exe /oobe /generalize /shutdown /mode:vm)

$TemplateVHDX = 'C:\Hyper-V\Templates\WS2012R2_WMF5_sysprepped_2016-06-17.vhdx'

#endregion

#region Scenario 1 - start a new VM based on a sysprepped master disk

# Helper-function to create virtual machine
. C:\DSC\New-DemoVM.ps1

New-DemoVM -VMName VM1 -TemplateVHDX $TemplateVHDX -MemoryStartupBytes 3GB
Start-VM -Name VM1

#endregion

#region Scenario 2 - start a new VM based on a sysprepped master disk, with unattend.xml injected

New-DemoVM -VMName VM2 -TemplateVHDX $TemplateVHDX -MemoryStartupBytes 3GB

# Inject unattend-file with local administrator password and settings for skipping OOBE (manual approach)
$UnattendFile = 'C:\Hyper-V\Unattend-files\unattend_minimal_bootstrap.xml'
psedit $UnattendFile
Copy-Item -Path $UnattendFile -Destination D:\Windows\Panther\unattend.xml
Start-VM -Name VM2

#endregion

#region Scenario 3 - start a new VM based on a sysprepped master disk, with unattend.xml and MetaConfig.mof injected

# Prerequisites: .meta.mof file available
psedit 'C:\DSC\Azure Automation DSC - bootstrap config.ps1'

New-DemoVM -VMName VM3 -TemplateVHDX $TemplateVHDX -MemoryStartupBytes 3GB

$VHDXPath = (Get-VM VM3 | Get-VMHardDiskDrive).Path

# Retrieve drive letter for mounted VHDX-file to inject files into
$before = Get-Volume
$VHDMount = Mount-DiskImage -ImagePath $VHDXPath -PassThru -StorageType VHDX
$after = Get-Volume | Where-Object FileSystemLabel -ne 'System Reserved'
$VMSystemDrive = (Compare-Object $before $after -Passthru -Property DriveLetter | Where-Object DriveLetter).DriveLetter + ':'

# Inject unattend-file with local administrator password and settings for skipping OOBE 
$Destination = Join-Path -Path $VMSystemDrive -ChildPath Windows\Panther\unattend.xml
Copy-Item -Path $UnattendFile -Destination $Destination

# Inject metaconfiguration into VHDX for bootstrapping the VM to Azure Automation DSC
$DSCMetaConfiguration = Join-Path -Path $env:temp\DscMetaConfigs -ChildPath VM3.meta.mof
$Destination = Join-Path -Path $VMSystemDrive -ChildPath Windows\System32\Configuration\MetaConfig.mof
Copy-Item -Path $DSCMetaConfiguration -Destination $Destination

# Remove local copy since this contains a secret (registration key)
Remove-Item $DSCMetaConfiguration

Dismount-DiskImage -InputObject $VHDMount

Start-VM -Name VM3

New-DemoVM -VMName VM3 -TemplateVHDX $TemplateVHDX -MemoryStartupBytes 3GB -DSCMetaConfiguration $DSCMetaConfiguration -UnattendXml $UnattendFile

Start-VM -Name VM3

#endregion

#region Resources

<#

*Summary*
The technique show cased in this demonstration can be used to bootstrap virtual machines only with the DSC meta 
configuration (.meta.mof) generated for connecting to Azure Automation DSC as a pull server.
That way, the configurations and all others settings (credentials, global variables, etc) can be dynamically retrieved from 
Azure Automation. Another advantage of using Azure Automation DSC as a pull server in general, is that you do not need to 
handle the encryption certificatite yourself. During the bootstrapping process Azure Automation DSC will automatically create
a certificate in the local machine`s certificate store for this purpose (CN=DSC-OaaS).

*Documentation - Azure Automation DSC*
https://azure.microsoft.com/en-us/documentation/articles/automation-dsc-overview/

*Lability*
A module for creating lab environments which leverages the concept of injecting DSC configurations into the virtual machines 
hard disk file. Can be configured to only inject meta-configurations in order to leverage Azure Automation DSC for configurations and assets.
https://github.com/VirtualEngine/Lability

There is also an article covering the concepts and basics of Lability on PowerShell Magazine:
http://www.powershellmagazine.com/?p=12460

*Sysprep*
https://technet.microsoft.com/en-us/library/cc749415(v=ws.10).aspx

*Demo scripts*
https://github.com/janegilring/PSCommunity/tree/master/DSC/Azure Automation DSC bootstrap

#>

#endregion