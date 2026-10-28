[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$ToolsDirectory, [switch]$IncludeInno)
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
if ($env:GITHUB_OUTPUT) {
    "autoit_directory=$autoit" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    "autoit3wrapper_path=$wrapper" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
}
if ($IncludeInno) {
    $inno = Join-Path $root 'inno'
    if (Test-Path -LiteralPath $inno) { throw "Destination already exists: $inno" }
    $installer = Join-Path $root 'inno-setup.exe'
    $url = 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe'
    $hash = '9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732'
    Invoke-WebRequest -Uri $url -OutFile $installer
    if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw 'Inno Setup checksum mismatch.' }
    $arguments = '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /PORTABLE=1 /DIR="' + $inno + '"'
    $process = Start-Process -FilePath $installer -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Inno Setup installation failed: $($process.ExitCode)" }
    $iscc = Get-ChildItem -LiteralPath $inno -Filter ISCC.exe -File -Recurse | Select-Object -First 1
    if (-not $iscc) { throw 'ISCC.exe not found.' }
    if ($env:GITHUB_OUTPUT) { "iscc_path=$($iscc.FullName)" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append }
    Write-Host "Inno Setup compiler: $($iscc.FullName)"
}
