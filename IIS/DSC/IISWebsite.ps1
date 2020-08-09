Configuration IISConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration #-ModuleVersion "3.2.0"
    Node $Allnodes.nodename
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }
                
        # Stop the default website
        xWebsite DefaultSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
        }

        xWebAppPool DefaultAppPool
        {
            Name                           = "DefaultAppPool";
            Ensure                         = "Absent";
        }

        xWebAppPool DefaultAppPool
        {
            Name                           = ".NET v4.5 Classic";
            Ensure                         = "Absent";
        }

        xWebAppPool DefaultAppPool
        {
            Name                           = ".NET v4.5";
            Ensure                         = "Absent";
        }


        xWebAppPool mysiteAppPool
        {
            autoShutdownExe                = "";
            autoShutdownParams             = "";
            autoStart                      = $True;
            CLRConfigFile                  = "";
            cpuAction                      = "NoAction";
            cpuLimit                       = 0;
            cpuResetInterval               = "00:05:00";
            cpuSmpAffinitized              = $False;
            cpuSmpProcessorAffinityMask    = 4294967295;
            cpuSmpProcessorAffinityMask2   = 4294967295;
            disallowOverlappingRotation    = $False;
            disallowRotationOnConfigChange = $False;
            enable32BitAppOnWin64          = $False;
            enableConfigurationOverride    = $True;
            Ensure                         = "Present";
            identityType                   = "ApplicationPoolIdentity";
            idleTimeout                    = "00:20:00";
            idleTimeoutAction              = "Terminate";
            loadBalancerCapabilities       = "HttpLevel";
            loadUserProfile                = $False;
            logEventOnProcessModel         = "IdleTimeout";
            logEventOnRecycle              = "Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory";
            logonType                      = "LogonBatch";
            managedPipelineMode            = "Integrated";
            managedRuntimeLoader           = "webengine4.dll";
            managedRuntimeVersion          = "v4.0";
            manualGroupMembership          = $False;
            maxProcesses                   = 1;
            Name                           = "mysite";
            orphanActionExe                = "";
            orphanActionParams             = "";
            orphanWorkerProcess            = $False;
            passAnonymousToken             = $True;
            pingingEnabled                 = $True;
            pingInterval                   = "00:00:30";
            pingResponseTime               = "00:01:30";
            queueLength                    = 1000;
            rapidFailProtection            = $True;
            rapidFailProtectionInterval    = "00:05:00";
            rapidFailProtectionMaxCrashes  = 5;
            restartMemoryLimit             = 0;
            restartPrivateMemoryLimit      = 0;
            restartRequestsLimit           = 0;
            restartSchedule                = @();
            restartTimeLimit               = "1.05:00:00";
            setProfileEnvironment          = $True;
            shutdownTimeLimit              = "00:01:30";
            startMode                      = "OnDemand";
            startupTimeLimit               = "00:01:30";
            State                          = "Started";
        }

        xWebsite {
            ApplicationPool          = "mysite";
            AuthenticationInfo       = "
				MSFT_xWebAuthenticationInformation
				{
					Basic = $False;
					Anonymous = $False;
					Digest = $False;
					Windows = $True;
				}";
            BindingInfo              = @("
				MSFT_xWebBindingInformation
				{
					Protocol = 'http';
					SslFlags = 0;
					IPAddress = '*';
					Port = 80;
					Hostname = '';
				}");
            DefaultPage              = @("Default.htm","Default.asp","index.htm","index.html","iisstart.htm","default.aspx");
            EnabledProtocols         = "http";
            Ensure                   = "Present";
            LogCustomFields          = "";
            LogFlags                 = @("Date","Time","ClientIP","UserName","ServerIP","Method","UriStem","UriQuery","HttpStatus","Win32Status","TimeTaken","ServerPort","UserAgent","Referer","HttpSubStatus");
            LogFormat                = "W3C";
            LoglocalTimeRollover     = $False;
            LogPath                  = "%SystemDrive%\inetpub\logs\LogFiles";
            LogPeriod                = "Daily";
            LogTargetW3C             = "File";
            LogtruncateSize          = 20971520;
            Name                     = "mysite";
            PhysicalPath             = "C:\inetpub\wwwroot";
            PreloadEnabled           = $False;
            ServerAutoStart          = $True;
            ServiceAutoStartEnabled  = $False;
            ServiceAutoStartProvider = "";
            SiteId                   = 1;
            State                    = "Started";
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $True
        }

    }
}
$ConfigData = @{
    AllNodes = @(
    @{
        NodeName = "LABIIS01";
        PSDscAllowPlainTextPassword = $true;
        PSDscAllowDomainUser = $true;
    }
)}
IISConfiguration -ConfigurationData $ConfigData

<#
	Remove-DscConfigurationDocument -Stage Pending,Current,Previous -Force
	Start-DscConfiguration -Path .\IISConfiguration -Verbose -Wait
	Test-DscConfiguration -Verbose
	Get-DscConfigurationStatus
	Get-DscConfigurationStatus -All
#>
