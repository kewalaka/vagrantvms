## Some Vagrant machines

Needs more docs, just some random machines built using Vagrant for now.

Find vagrant machines with vagrant global-status

Add machines example

```
vagrant box add win10-1903 D:\Vagrant\Win10\1903\windows_10_hyperv.box
```

### Setup

```
winrm quickconfig
```

Make sure client workstation will trust hosts created in hypervisor

```
winrm s winrm/config/client '@{TrustedHosts="192.168.*,10.*"}'
```

output:

```
C:\WINDOWS\system32> winrm s winrm/config/client '@{TrustedHosts="192.168.*,10.*"}'
Client
    NetworkDelayms = 5000
    URLPrefix = wsman
    AllowUnencrypted = false
    Auth
        Basic = true
        Digest = true
        Kerberos = true
        Negotiate = true
        Certificate = true
        CredSSP = false
    DefaultPorts
        HTTP = 5985
        HTTPS = 5986
    TrustedHosts = 192.168.*,10.*
```
