param([Parameter(Mandatory=$true)][string]$Installer)
$ErrorActionPreference = 'Stop'
$setup = (Resolve-Path -LiteralPath $Installer).Path
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$name = 'LeoMoon SessionGuard'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{93D9AB2D-8CB1-4C47-B305-932988173887}_is1'
if (Get-Process -Name $name -ErrorAction SilentlyContinue) { throw 'SessionGuard is already running.' }
if (Test-Path -LiteralPath $uninstallKey) { throw 'SessionGuard is already installed.' }
if ((Get-Item -LiteralPath $run).GetValueNames() -contains $name) { throw 'A startup entry already exists.' }
$dir = Join-Path ([IO.Path]::GetTempPath()) ('sessionguard-package-test-' + [guid]::NewGuid().ToString('N'))
$installed = Join-Path $dir 'LeoMoon SessionGuard.exe'
$uninstaller = Join-Path $dir 'unins000.exe'
$uninstalled = $false
try {
    $args = '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="' + $dir + '"'
    $p = Start-Process -FilePath $setup -ArgumentList $args -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $installed)) { throw 'Installation failed.' }
    if ((Get-Item -LiteralPath $run).GetValue($name) -ne ('"' + $installed + '"')) { throw 'Default install did not enable startup.' }
    & (Join-Path $PSScriptRoot 'BuildSmoke.ps1') -Executable $installed
    $ini = Join-Path $dir 'LeoMoon SessionGuard.ini'
    [IO.File]::WriteAllText($ini, "[Options]`r`nMain=^!1`r`n")
    $p = Start-Process -FilePath $setup -ArgumentList $args -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0 -or [IO.File]::ReadAllText($ini) -ne "[Options]`r`nMain=^!1`r`n") { throw 'Upgrade did not preserve settings.' }
    $p = Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0) { throw 'Uninstall failed.' }
    $uninstalled = $true
    if ((Get-Item -LiteralPath $run).GetValueNames() -contains $name) { throw 'Uninstall left the startup entry.' }
    if (-not (Test-Path -LiteralPath $ini)) { throw 'Uninstall did not preserve settings.' }
    if (Get-Process -Name $name -ErrorAction SilentlyContinue) { throw 'SessionGuard process remains.' }
    $uninstalled = $false
    $uncheckedArgs = $args + ' /TASKS=""'
    $p = Start-Process -FilePath $setup -ArgumentList $uncheckedArgs -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0 -or (Get-Item -LiteralPath $run).GetValueNames() -contains $name) { throw 'Unchecked startup was not respected.' }
    $p = Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0) { throw 'Unchecked-startup uninstall failed.' }
    $uninstalled = $true
    Write-Host 'Installer smoke checks passed.'
} finally {
    if (-not $uninstalled -and (Test-Path -LiteralPath $uninstaller)) {
        Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -WindowStyle Hidden -Wait
    }
    $remaining = (Get-Item -LiteralPath $run).GetValue($name)
    if ($remaining -eq ('"' + $installed + '"')) { Remove-ItemProperty -LiteralPath $run -Name $name }
    if (Test-Path -LiteralPath $dir) {
        $resolved = (Resolve-Path -LiteralPath $dir).Path
        if ($resolved -eq $dir -and $dir.StartsWith([IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $dir -Recurse -Force }
    }
}
