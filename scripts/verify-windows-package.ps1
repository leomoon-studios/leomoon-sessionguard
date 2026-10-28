[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ArtifactDirectory,
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version
)
$ErrorActionPreference = 'Stop'
$dir = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$zip = "leomoon-sessionguard-$Version-windows-x86-portable.zip"
$setup = "leomoon-sessionguard-$Version-windows-x86-setup.exe"
$expected = @($zip,$setup,'release-manifest.json','SHA256SUMS') | Sort-Object
$actual = @(Get-ChildItem -LiteralPath $dir -Force | Select-Object -ExpandProperty Name | Sort-Object)
if (($expected -join "`n") -ne ($actual -join "`n")) { throw 'Unexpected artifact list.' }
$lines = @(Get-Content -LiteralPath (Join-Path $dir 'SHA256SUMS'))
if ($lines.Count -ne 3) { throw 'Invalid checksum count.' }
$names = @()
foreach ($line in $lines) {
    if ($line -notmatch '^([0-9a-f]{64}) \*([^\\/]+)$') { throw 'Invalid checksum entry.' }
    $hash = $Matches[1]; $name = $Matches[2]; $names += $name
    if ((Get-FileHash -LiteralPath (Join-Path $dir $name) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw "Checksum mismatch: $name" }
}
if ((($names | Sort-Object) -join "`n") -ne ((@($zip,$setup,'release-manifest.json') | Sort-Object) -join "`n")) { throw 'Checksum names do not match artifacts.' }
$manifest = Get-Content -LiteralPath (Join-Path $dir 'release-manifest.json') -Raw | ConvertFrom-Json
if ($manifest.application -ne 'LeoMoon SessionGuard' -or $manifest.version -ne $Version -or $manifest.fileVersion -ne "$Version.0" -or $manifest.architecture -ne 'x86' -or $manifest.platform -ne 'windows' -or $manifest.signed -ne $false) { throw 'Invalid manifest.' }
if ((@($manifest.artifacts | Sort-Object) -join "`n") -ne ((@($zip,$setup) | Sort-Object) -join "`n")) { throw 'Invalid manifest artifacts.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $dir $zip))
try {
    if ($archive.Entries.Count -ne 1 -or $archive.Entries[0].FullName -ne 'LeoMoon SessionGuard.exe') { throw 'Portable ZIP must contain exactly the application executable.' }
    $stream = $archive.Entries[0].Open(); $memory = [IO.MemoryStream]::new()
    try { $stream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
    if ($bytes.Length -lt 64 -or $bytes[0] -ne 77 -or $bytes[1] -ne 90) { throw 'Invalid application PE.' }
    $offset = [BitConverter]::ToInt32($bytes, 0x3c)
    if ($offset -lt 0 -or $offset + 6 -gt $bytes.Length -or [BitConverter]::ToUInt16($bytes, $offset + 4) -ne 0x14c) { throw 'Application is not x86.' }
    $temporary = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllBytes($temporary, $bytes)
        $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($temporary)
        if ($info.FileVersion -ne "$Version.0" -or $info.ProductVersion -ne "$Version.0") { throw 'Portable executable version mismatch.' }
    } finally { Remove-Item -LiteralPath $temporary -Force }
} finally { $archive.Dispose() }
$setupInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $dir $setup))
if ($setupInfo.FileVersion.Trim() -ne "$Version.0" -or $setupInfo.ProductVersion.Trim() -ne "$Version.0") { throw 'Installer version mismatch.' }
Write-Host 'Package verification passed.'
