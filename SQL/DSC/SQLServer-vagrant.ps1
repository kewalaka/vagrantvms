Param
(
  # Domain Admin Password
  [Parameter(Mandatory = $true)]
  $Passwords
)

# install depedent modules
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module PSDesiredStateConfiguration, SQLServerDsc, SecurityPolicyDsc

# load in the configuration document
. $PSScriptRoot\SQLServer.ps1

# The folder to do the work
$DSCFolder = Split-Path $env:DSC_CertLocation

# create username/password credential objects from parameters
$secureString = $Passwords | ConvertTo-SecureString -AsPlainText -Force
$PasswordCredential = New-Object -TypeName System.Management.Automation.PSCredential `
  -ArgumentList 'Administrator', $secureString

# produce the MOF
SQLServer -OutputPath $DSCFolder `
  -SqlServiceCredential $PasswordCredential `
  -SqlAgentServiceCredential $PasswordCredential `
  -SqlAdminCredential $PasswordCredential 

# set up the LCM to use the certificate
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose

#$DSCFolder = Split-Path $env:DSC_CertLocation
#$x = Test-DscConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose
#Start-DSCConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Force -Verbose -Wait
# 