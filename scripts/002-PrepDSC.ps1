Install-PackageProvider -Name NuGet -Force

# DSC onboarding
. $PSScriptRoot\Register-DscCertificate.ps1
