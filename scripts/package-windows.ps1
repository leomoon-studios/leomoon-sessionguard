[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [Parameter(Mandatory=$true)][string]$StageDirectory,
    [Parameter(Mandatory=$true)][string]$DistDirectory,
    [Parameter(Mandatory=$true)][string]$IsccPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{7,64}$')][string]$Commit
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stage = (Resolve-Path -LiteralPath $StageDirectory).Path
$exe = Join-Path $stage 'LeoMoon SessionGuard.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Application executable not found.' }
$info = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
if ($info.FileVersion -ne "$Version.0" -or $info.ProductVersion -ne "$Version.0") { throw 'Application version mismatch.' }
$hasCertificate = -not [string]::IsNullOrWhiteSpace($env:WINDOWS_CERTIFICATE_BASE64)
$hasPassword = -not [string]::IsNullOrEmpty($env:WINDOWS_CERTIFICATE_PASSWORD)
if ($hasCertificate -ne $hasPassword) { throw 'Both Windows signing secrets are required.' }
if ($hasCertificate) { & (Join-Path $PSScriptRoot 'sign-windows.ps1') -Path $exe }
$dist = [IO.Path]::GetFullPath($DistDirectory)
if (Test-Path -LiteralPath $dist) {
    if (@(Get-ChildItem -LiteralPath $dist -Force).Count -ne 0) { throw "Artifact directory is not empty: $dist" }
} else { New-Item -ItemType Directory -Path $dist | Out-Null }
$zipName = "leomoon-sessionguard-$Version-windows-x86-portable.zip"
$setupName = "leomoon-sessionguard-$Version-windows-x86-setup.exe"
Compress-Archive -LiteralPath $exe -DestinationPath (Join-Path $dist $zipName)
$iss = Join-Path $root 'packaging\windows\sessionguard.iss'
& $IsccPath '/Qp' "/DAppVersion=$Version" "/DStageDir=$stage" "/DOutputDir=$dist" $iss
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $dist $setupName))) { throw 'Installer compilation failed.' }
if ($hasCertificate) { & (Join-Path $PSScriptRoot 'sign-windows.ps1') -Path (Join-Path $dist $setupName) }
$manifest = [ordered]@{ application='LeoMoon SessionGuard'; version=$Version; fileVersion="$Version.0"; commit=$Commit.ToLowerInvariant(); platform='windows'; architecture='x86'; signed=$hasCertificate; artifacts=@($zipName,$setupName) }
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dist 'release-manifest.json') -Encoding UTF8
@($zipName,$setupName,'release-manifest.json') | Sort-Object | ForEach-Object {
    '{0} *{1}' -f (Get-FileHash -LiteralPath (Join-Path $dist $_) -Algorithm SHA256).Hash.ToLowerInvariant(), $_
} | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS') -Encoding ASCII
& (Join-Path $PSScriptRoot 'verify-windows-package.ps1') -ArtifactDirectory $dist -Version $Version
Write-Host "Artifacts: $dist"
