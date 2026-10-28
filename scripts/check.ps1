[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$ToolchainDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$checker = Join-Path $ToolchainDirectory 'Au3Check.exe'
$autoit = Join-Path $ToolchainDirectory 'AutoIt3.exe'
foreach ($path in @($checker, $autoit)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing tool: $path" }
}
$tests = @((Join-Path $root 'tests\TestRunner.au3'), (Join-Path $root 'tests\TraySmoke.au3'))
$targets = @((Join-Path $root 'src\LeoMoon SessionGuard.au3')) + $tests
foreach ($target in $targets) {
    & $checker -q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w- 7 -I (Join-Path $root 'src') $target
    if ($LASTEXITCODE -ne 0) { throw "Au3Check failed: $target" }
}
$before = @(& git -C $root status --porcelain)
foreach ($test in $tests) {
    $process = Start-Process -FilePath $autoit -ArgumentList ('/ErrorStdOut "' + $test + '"') -WorkingDirectory (Join-Path $root 'tests') -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Test failed: $test ($($process.ExitCode))" }
}
$after = @(& git -C $root status --porcelain)
if (($before -join "`n") -ne ($after -join "`n")) { throw 'Tests changed the worktree.' }
Write-Host 'Checks passed.'
