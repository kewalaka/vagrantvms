Configuration SQLServer
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $SqlServiceCredential,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $SqlAgentServiceCredential,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $SqlAdminCredential,

    $AdditionalSysAdmins = @(),

    $SQLVersion = '2016',

    $NameOfInstance = 'MSSQLSERVER'  # MSSQLSERVER = default instance
  )

  Import-DSCResource -ModuleName PSDesiredStateConfiguration, SQLServerDsc, SecurityPolicyDsc

  $SourcePath = 'D:\'
  $ServerName = 'localhost'

  $SysAdmins = @('BUILTIN\Administrators')

  Node $AllNodes.Nodename
  {
    LocalConfigurationManager { 
      CertificateId      = $Node.Thumbprint 
      RebootNodeIfNeeded = $Node.RebootIfNeeded
    } 

    if ($SQLVersion -eq '2014') {
      #region Install prerequisites for SQL Server
      Script enableDotNet {
        GetScript  = { (Get-WindowsOptionalFeature -FeatureName 'NetFx3' -Online).State }
        TestScript = { (Get-WindowsOptionalFeature -FeatureName 'NetFx3' -Online).State -eq 'Enabled' }
        SetScript  = { Enable-WindowsOptionalFeature -FeatureName 'NetFx3' -NoRestart -Online -All }
      }
        
      WindowsFeature 'NetFramework45' {
        Name      = 'NET-Framework-45-Core'
        Ensure    = 'Present'
        DependsOn = '[Script]enableDotNet'
      }        
    }
    else {
      WindowsFeature 'NetFramework45' {
        Name   = 'NET-Framework-45-Core'
        Ensure = 'Present'
      }
    }

    #endregion

    $rootPath = 'C:\Data\SQL'
    SqlSetup 'InstallDefaultInstance'
    {
      InstanceName        = $NameOfInstance
      Features            = 'SQLENGINE' #,REPLICATION,FULLTEXT'
      SQLCollation        = 'SQL_Latin1_General_CP1_CI_AS'
      SQLSvcAccount       = $SqlServiceCredential
      AgtSvcAccount       = $SqlAgentServiceCredential
      SQLSysAdminAccounts = $SysAdmins
      InstallSQLDataDir   = "$rootPath\DB"
      SQLUserDBDir        = "$rootPath\DB"
      SQLUserDBLogDir     = "$rootPath\Logs"
      SQLTempDBDir        = "$rootPath\DB"
      SQLTempDBLogDir     = "$rootPath\Logs"
      SQLBackupDir        = 'C:\SQLBackups'
      SourcePath          = $SourcePath
      UpdateEnabled       = 'False'
      AgtSvcStartupType   = 'Automatic'
      ForceReboot         = $false
      <#
        Not released yet;

        SqlTempdbFileCount     = 4
        SqlTempdbFileSize      = 1024
        SqlTempdbFileGrowth    = 512
        SqlTempdbLogFileSize   = 128
        SqlTempdbLogFileGrowth = 64
        #>
      DependsOn           = '[WindowsFeature]NetFramework45'
    }

    SqlMemory Set_SqlMaxMemory
    {
      DynamicAlloc = $true
      InstanceName = $NameOfInstance
      DependsOn    = '[SqlSetup]InstallDefaultInstance'
    } 

    # Set mixed mode using registry - TODO fix when a proper resource has been created
    switch ($SQLVersion) {
      '2014' { $SQLShortVersion = '12' }
      '2016' { $SQLShortVersion = '13' }
      '2017' { $SQLShortVersion = '14' }
      '2019' { $SQLShortVersion = '15' }
      Default { $SQLShortVersion = '13' }
    }
    Registry SetMixedModeAuth {
      Ensure    = 'Present'        
      Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL$SQLShortVersion.MSSQLSERVER\$NameOfInstance"
      ValueName = 'LoginMode'
      ValueData = '2'
      ValueType = 'Dword'
      Force     = $true
    }

    SqlWindowsFirewall Create_FirewallRules_For_SQL2016
    {
      Features     = 'SQLENGINE'
      InstanceName = $NameOfInstance
      SourcePath   = $SourcePath
      DependsOn    = '[SqlSetup]InstallDefaultInstance'
    } 
  
    # auto is calculated as per this formula
    # https://github.com/PowerShell/SqlServerDsc#formula-for-dynamically-allocating-max-degree-of-parallelism
    SqlMaxDop Set_SqlMaxDop_ToAuto
    {
      DynamicAlloc = $true
      InstanceName = $NameOfInstance
      DependsOn    = '[SqlSetup]InstallDefaultInstance'
    }    

    # Ensure TCP is enabled, configure SQL with a static port - TCP1433
    SqlProtocol 'EnableTcpProtocol'
    {
      InstanceName    = $NameOfInstance
      ProtocolName    = 'TcpIp'
      Enabled         = $true
      SuppressRestart = $false
      ServerName      = $ServerName
      DependsOn       = '[SqlSetup]InstallDefaultInstance'
    }

    SqlProtocolTcpIP 'SetStaticTcpPort'
    {     
      InstanceName      = $NameOfInstance
      UseTCPDynamicPort = $false
      TCPPort           = 1433
      IpAddressGroup    = 'IPAll'
      DependsOn         = '[SqlProtocol]EnableTcpProtocol'
    }

    # enable backup compression by default
    SqlConfiguration 'BackupCompressionDefault'
    {
      ServerName     = $ServerName    
      InstanceName   = $NameOfInstance
      OptionName     = 'backup compression default'
      OptionValue    = 1
      RestartService = $false
      DependsOn      = '[SqlSetup]InstallDefaultInstance'
    }

    # this allows SQL to perform instant file initialization
    # https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization
    UserRightsAssignment PerformVolumeMaintenanceTasks
    {
      Policy   = "Perform_volume_maintenance_tasks"
      Identity = $SqlServiceCredential.UserName
    }

    # enable remote dedicated admin connection
    # https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/remote-admin-connections-server-configuration-option?view=sql-server-2017
    SqlConfiguration 'EnableDedicatedAdminConnection'
    {
      ServerName     = $ServerName    
      InstanceName   = $NameOfInstance
      OptionName     = 'remote admin connections'
      OptionValue    = 1
      RestartService = $false
      DependsOn      = '[SqlSetup]InstallDefaultInstance'
    }

    # model is the default used for other databases
    SqlDatabaseRecoveryModel 'ModelDBRecoveryModel'
    {
      Name                 = 'model'
      RecoveryModel        = 'Simple'
      ServerName           = $ServerName
      InstanceName         = $NameOfInstance
      PsDscRunAsCredential = $SqlAdminCredential
      DependsOn            = '[SqlSetup]InstallDefaultInstance'
    }
  }
}