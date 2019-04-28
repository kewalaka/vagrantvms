# Package management
. $PSScriptRoot\Install-Chocolatey.ps1
RefreshEnv.cmd

# install PS5.1
choco install powershell -y
