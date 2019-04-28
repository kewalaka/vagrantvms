$DSCCertLocation = 'C:\Admin\DSC\DscPublicKey.cer'
$DSCCertFriendlyName = 'DSC Credential Encryption certificate'

# create the folder for the certificate & MOF files
New-Item -Path (Split-Path $DSCCertLocation) -ItemType Directory -ErrorAction SilentlyContinue

# this allows the correct key usage to be set on earlier OS (pre2016), and works on 2016+ too
. $PSScriptRoot\New-SelfSignedCertificateEx.ps1

New-SelfsignedCertificateEx `
    -Subject "CN=${ENV:ComputerName}" `
    -EKU 'Document Encryption' `
    -KeyUsage 'KeyEncipherment, DataEncipherment' `
    -SAN ${ENV:ComputerName} `
    -FriendlyName $DSCCertFriendlyName `
    -Exportable `
    -StoreLocation 'LocalMachine' `
    -KeyLength 2048 `
    -ProviderName 'Microsoft Enhanced Cryptographic Provider v1.0' `
    -AlgorithmName 'RSA' `
    -SignatureAlgorithm 'SHA256'
# Locate the newly created certificate
$Cert = Get-ChildItem -Path cert:\LocalMachine\My `
    | Where-Object {
        ($_.FriendlyName -eq $DSCCertFriendlyName) `
        -and ($_.Subject -eq "CN=${ENV:ComputerName}")
    } | Select-Object -First 1
# export the public key certificate
$cert | Export-Certificate -FilePath $DSCCertLocation -Force

# set environment variables to be used in scripts
[Environment]::SetEnvironmentVariable("DSC_CertLocation", ($DSCCertLocation), "Machine")
[Environment]::SetEnvironmentVariable("DSC_CertThumbprint", ($cert.Thumbprint), "Machine")
