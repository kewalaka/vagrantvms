[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force

# these appear to disappear sometimes!
Register-PSRepository -Default
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# DSC onboarding
. $PSScriptRoot\Register-DscCertificate.ps1
