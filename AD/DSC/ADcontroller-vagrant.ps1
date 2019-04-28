Param
(
    # Domain Admin Password
    [Parameter(Mandatory=$true)]
    $domainAdminPassword,

    # Safe Mode Password
    [Parameter(Mandatory=$true)]
    $safeModePassword
)

# install depedent modules
Install-Module xActiveDirectory, xPendingReboot, xDNSServer, xDhcpServer, xNetworking -Force

# load in the configuration document
. $PSScriptRoot\ADcontroller.ps1

# environment specific settings
$DomainNetBIOSName = 'methanex'
$ConfigData =  @{
    AllNodes = @(

        @{
            Nodename = "*"
            DomainName = "methanex.com"
            DomainNetBIOSName = $DomainNetBIOSName
            CertificateFile = $env:DSC_CertLocation
            Thumbprint = $env:DSC_CertThumbprint
            RetryCount = 20
            RetryIntervalSec = 30
            PSDscAllowDomainUser = $true
            RebootIfNeeded = $true
            DNSForwarders = @('8.8.8.8', '8.8.4.4')
        },

        @{
            Nodename = "labdc01"
            Role = "First DC"
            SiteName = "labsite1"
        },

        @{
            Nodename = "labdc02"
            Role = "Additional DC"
            SiteName = "labsite1"            
        }
    )
}

# The folder to do the work
$DSCFolder = Split-Path $env:DSC_CertLocation

# create username/password credential objects from parameters
$secureString = $domainAdminPassword | ConvertTo-SecureString -AsPlainText -Force
$domainAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                    -ArgumentList 'Administrator', $secureString

$secureString = $safeModePassword | ConvertTo-SecureString -AsPlainText -Force
$safeModeCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                 -ArgumentList 'Administrator', $secureString

# produce the MOF
ADcontroller -OutputPath $DSCFolder -ConfigurationData $ConfigData `
-safemodeAdminCred $safeModeCredential `
-domainAdminCred $domainAdminCredential 

# set up the LCM to use the certificate
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose

#$DSCFolder = Split-Path $env:DSC_CertLocation
#$x = Test-DscConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Verbose
Start-DSCConfiguration -ComputerName $env:COMPUTERNAME -Path $DSCFolder -Force -Verbose -Wait
# 