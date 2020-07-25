# A configuration to Create High Availability Domain Controller
Configuration ADcontroller
{
    param
    (
        # safe mode administrator password - don't forget this must meet default complexity requirements
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdminCred,

        # domain administrator password - don't forget this must meet default complexity requirements
        [Parameter(Mandatory)]
        [pscredential]$domainAdminCred
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration,xActiveDirectory,xPendingReboot,xDnsServer,xDhcpServer,xNetworking

    #region: Use supplied DatabasePath and LogPath, or default location otherwise
    # if the database path has been specified
    if ($AllNodes.DatabasePath)
    {
        $DatabasePath = $AllNodes.DatabasePath
        if ($AllNodes.LogPath)
        {
            $LogPath = $AllNodes.LogPath
        }
        else
        {
            # if the database path has been specified but not the logpath, assume they should be the same
            $LogPath = $AllNodes.DatabasePath
        }
    }
    else
    {   
        # stick with the default
        $DatabasePath = $LogPath = 'C:\Windows\NTDS'
    }
    #endregion

    #region: Set up LCM, Install AD features & tools, and set networking to static IPs.
    Node $AllNodes.Nodename
    {
        LocalConfigurationManager 
        { 
                CertificateId = $Node.Thumbprint 
                RebootNodeIfNeeded = $Node.RebootIfNeeded
        } 

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature ADDSToolsInstall {
            Ensure = 'Present'
            Name = 'RSAT-ADDS-Tools'
        }

        xPendingReboot AfterADDSToolsinstall
        {
            Name = 'AfterADDSinstall'
            DependsOn = "[WindowsFeature]ADDSToolsInstall"
        }

        $AddressFamily = 'IPv4'
        # assumes a single NIC
        $network = Get-NetIPConfiguration
        $InterfaceAlias = $network.InterfaceAlias

        # Get IP Address details from DSC config or from existing machine if not specified
        if ($Node.IPAddress)
        {
            $IPAddress = $Node.IPAddress
        }
        else
        {
            $IPAddress = ($network.IPv4Address.IPAddress)+"/"+$network.IPv4Address.PrefixLength
        }

        # Get Gateway details from DSC config or from existing machine if not specified        
        if ($Node.Gateway)
        {
            $Gateway = $Node.Gateway
        }
        else
        {
            $Gateway = $network.IPv4DefaultGateway.NextHop
        }

        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }

        xIPAddress NewIPAddress
        {
            IPAddress      = $IPAddress
            InterfaceAlias = $InterfaceAlias          
            AddressFamily  = $AddressFamily
        }    

        xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = $Gateway
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
        
    }
    #endregion

    #region: Configure first domain controller, including sites & AD recycle bin
    Node $AllNodes.Where{$_.Role -eq "First DC"}.Nodename
    {  
        xADDomain FirstDS
        {
            DomainName = $Node.DomainName
            DomainNetBIOSName = $Node.DomainNetBIOSName
            DomainAdministratorCredential = $domainAdminCred
            SafemodeAdministratorPassword = $safemodeAdminCred
            #DatabasePath = 'D:\AD\Database'
            #LogPath = 'D:\AD\Logs'
            DependsOn = "[xPendingReboot]AfterADDSToolsinstall"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $domainAdminCred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        }

        xADReplicationSite ADSite
        {
            Name = $Node.SiteName
            RenameDefaultFirstSiteName = $true
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xADRecycleBin RecyclinBin
        {
            EnterpriseAdministratorCredential = $domainAdminCred
            ForestFQDN = $Node.DomainName
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot AfterADDSinstall
        {
            Name = 'AfterADDSinstall'
            DependsOn = "[xADRecycleBin]RecyclinBin"
        }   
    }
    #endregion

    #region: Configure additional domain controllers
    Node $AllNodes.Where{$_.Role -eq "Additional DC"}.Nodename
    {
        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $domainAdminCred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainController SecondDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainAdminCred
            SafemodeAdministratorPassword = $safemodeAdminCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
            #DatabasePath = 'D:\AD\Database'
            #LogPath = 'D:\AD\Logs'
        }

        xPendingReboot AfterADDSinstall
        {
            Name = 'AfterADDSinstall'
            DependsOn = "[xADDomainController]SecondDC"
        }
    }
    #endregion

    #region: enable DNS forwaders if requested
    If ($AllNodes.DNSForwarders)
    {
        Node $AllNodes.Nodename
        {
            xDnsServerForwarder SetForwarders
            {
                IsSingleInstance = 'Yes'
                IPAddresses = $Node.DNSForwarders
                DependsOn = "[xPendingReboot]AfterADDSinstall"
            }
        }    
    }
    #endregion
}
