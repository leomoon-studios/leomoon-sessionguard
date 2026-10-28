[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$ToolsDirectory)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($ToolsDirectory)
New-Item -ItemType Directory -Force -Path $root | Out-Null
$packages = @(
    @{ Name = 'autoit'; Url = 'https://www.autoitscript.com/autoit3/files/archive/autoit/autoit-v3.3.18.0.zip'; Hash = 'ceb666a993a9f62621c3a0d4ee602774b2e7f543de1f08ec0380632ee3f89beb' },
    @{ Name = 'scite'; Url = 'https://www.autoitscript.com/autoit3/scite/download/SciTE4AutoIt3_Portable.zip'; Hash = '9e41b60753b566af3333601a9720607fbf71a248c2e7225b5ee1fec0ca852722' }
)
foreach ($package in $packages) {
    $archive = Join-Path $root ($package.Name + '.zip')
    $destination = Join-Path $root $package.Name
    if (Test-Path -LiteralPath $destination) { throw "Destination already exists: $destination" }
    Invoke-WebRequest -Uri $package.Url -OutFile $archive
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.Hash) { throw "Checksum mismatch: $($package.Url)" }
    Expand-Archive -LiteralPath $archive -DestinationPath $destination
}
$autoit = Join-Path $root 'autoit\install'
$wrapper = Join-Path $root 'scite\AutoIt3Wrapper\AutoIt3Wrapper.au3'
foreach ($path in @((Join-Path $autoit 'AutoIt3.exe'), (Join-Path $autoit 'Au3Check.exe'), $wrapper)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing tool: $path" }
}
Write-Host "AutoIt directory: $autoit"
Write-Host "AutoIt3Wrapper: $wrapper"
