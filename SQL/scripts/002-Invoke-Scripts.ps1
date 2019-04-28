Install-PackageProvider -Name NuGet -Force
Install-Module SqlServerDsc -Force

# DSC onboarding
. $PSScriptRoot\Register-DscCertificate.ps1
