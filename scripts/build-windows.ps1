[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [Parameter(Mandatory = $true)][string]$AutoItDirectory,
    [Parameter(Mandatory = $true)][string]$AutoIt3WrapperPath
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $root ('build\staging-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $stage 'src'
$output = Join-Path $stage 'output'
New-Item -ItemType Directory -Force -Path $source, $output | Out-Null
Copy-Item -Path (Join-Path $root 'src\*') -Destination $source -Recurse -Force
$constants = Join-Path $source 'core\AppConstants.au3'
$text = [IO.File]::ReadAllText($constants)
$text = $text -replace '(?m)^Global Const \$APP_VERSION = .*$', "Global Const `$APP_VERSION = '$Version'"
$text = $text -replace '(?m)^#pragma compile\(FileVersion, .*\)\r?$', "#pragma compile(FileVersion, $Version.0)"
$text = $text -replace '(?m)^#pragma compile\(ProductVersion, .*\)\r?$', "#pragma compile(ProductVersion, $Version.0)"
if ($text -notmatch [regex]::Escape("Global Const `$APP_VERSION = '$Version'")) { throw 'Version injection failed.' }
[IO.File]::WriteAllText($constants, $text)
$main = Join-Path $source 'LeoMoon SessionGuard.au3'
$text = [IO.File]::ReadAllText($main) -replace '(?m)^#pragma compile\(Out,.*\)\r?$', '; Output supplied by build script.'
[IO.File]::WriteAllText($main, $text)
$exe = Join-Path $output 'LeoMoon SessionGuard.exe'
$autoit = Join-Path $AutoItDirectory 'AutoIt3.exe'
$arguments = '"' + $AutoIt3WrapperPath + '" /in "' + $main + '" /out "' + $exe + '" /x86 /NoStatus /NoPack /AutoIt3Dir "' + $AutoItDirectory + '"'
$process = Start-Process -FilePath $autoit -ArgumentList $arguments -WorkingDirectory $source -WindowStyle Hidden -PassThru -Wait
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $exe)) { throw 'Compilation failed.' }
if (-not ('SessionGuardBuildResources' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SessionGuardBuildResources {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr FindResource(IntPtr module, IntPtr name, IntPtr type);
    [DllImport("kernel32.dll")]
    public static extern bool FreeLibrary(IntPtr module);
}
'@
}
$module = [SessionGuardBuildResources]::LoadLibraryEx($exe, [IntPtr]::Zero, 2)
if ($module -eq [IntPtr]::Zero) { throw 'Unable to inspect compiled icon resources.' }
try {
    foreach ($iconId in @(201, 202)) {
        if ([SessionGuardBuildResources]::FindResource($module, [IntPtr]$iconId, [IntPtr]14) -eq [IntPtr]::Zero) { throw "Missing tray icon group $iconId." }
    }
} finally { [void][SessionGuardBuildResources]::FreeLibrary($module) }
$info = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
if ($info.FileVersion -ne "$Version.0" -or $info.ProductVersion -ne "$Version.0") { throw 'Compiled version does not match.' }
$bytes = [IO.File]::ReadAllBytes($exe)
$offset = [BitConverter]::ToInt32($bytes, 0x3c)
if ([BitConverter]::ToUInt16($bytes, $offset + 4) -ne 0x14c) { throw 'Compiled executable is not x86.' }
Write-Host "Built $exe"
if ($env:GITHUB_OUTPUT) { "output_directory=$output" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append }
