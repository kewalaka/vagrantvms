Param
(
  # Domain Admin Password
  [Parameter(Mandatory = $true)]
  $Passwords
)

# install depedent modules
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module SQLServerDsc, SecurityPolicyDsc

# load in the configuration document
. $PSScriptRoot\SQLServer.ps1

# The folder to do the work
$DSCFolder = Split-Path $env:DSC_CertLocation

# create username/password credential objects from parameters
$secureString = $Passwords | ConvertTo-SecureString -AsPlainText -Force
$AdminCredential = New-Object -TypeName System.Management.Automation.PSCredential `
  -ArgumentList "$env:USERDOMAIN\a-stu", $secureString

$SQLEngineCredential = New-Object -TypeName System.Management.Automation.PSCredential `
  -ArgumentList "$env:USERDOMAIN\s-sqlengine", $secureString

$SQLAgentCredential = New-Object -TypeName System.Management.Automation.PSCredential `
  -ArgumentList "$env:USERDOMAIN\s-sqlagent", $secureString

# environment specific settings
$ConfigData = @{
  AllNodes = @(

    @{
      Nodename             = "*"
      CertificateFile      = $env:DSC_CertLocation
      Thumbprint           = $env:DSC_CertThumbprint
      PSDscAllowDomainUser = $true
      RebootIfNeeded       = $true
    },

    @{
      Nodename = "labsql02"
    }
  )
}

# produce the MOF
SQLServer -OutputPath $DSCFolder -ConfigurationData $ConfigData `
  -SqlServiceCredential $SQLEngineCredential `
  -SqlAgentServiceCredential $SQLAgentCredential `
  -SqlAdminCredential $AdminCredential `
  -NameOfInstance "INST1"

# set up the LCM to use the certificate
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose

#$DSCFolder = Split-Path $env:DSC_CertLocation
#$x = Test-DscConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose
#Start-DSCConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Force -Verbose -Wait
# 