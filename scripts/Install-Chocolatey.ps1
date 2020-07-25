$env:chocolateyUseWindowsCompression = 'false'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))


