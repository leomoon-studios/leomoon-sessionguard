param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [Parameter(Mandatory=$true)][string]$StageDirectory,
    [Parameter(Mandatory=$true)][string]$IsccPath
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$work = Join-Path $root ('build\signing-smoke-' + [guid]::NewGuid().ToString('N'))
$oldCertificate = $env:WINDOWS_CERTIFICATE_BASE64
$oldPassword = $env:WINDOWS_CERTIFICATE_PASSWORD
try {
    $env:WINDOWS_CERTIFICATE_BASE64 = 'dGVzdA=='
    $env:WINDOWS_CERTIFICATE_PASSWORD = ''
    $failed = $false
    try { & (Join-Path $root 'scripts\package-windows.ps1') -Version $Version -StageDirectory $StageDirectory -DistDirectory (Join-Path $work 'partial') -IsccPath $IsccPath -Commit 1234567 } catch { $failed = $_.Exception.Message -match 'Both Windows signing secrets' }
    if (-not $failed) { throw 'Certificate without password did not fail clearly.' }
    $env:WINDOWS_CERTIFICATE_BASE64 = ''
    $env:WINDOWS_CERTIFICATE_PASSWORD = 'test'
    $failed = $false
    try { & (Join-Path $root 'scripts\package-windows.ps1') -Version $Version -StageDirectory $StageDirectory -DistDirectory (Join-Path $work 'partial') -IsccPath $IsccPath -Commit 1234567 } catch { $failed = $_.Exception.Message -match 'Both Windows signing secrets' }
    if (-not $failed) { throw 'Password without certificate did not fail clearly.' }
    $env:WINDOWS_CERTIFICATE_BASE64 = ''
    $env:WINDOWS_CERTIFICATE_PASSWORD = ''
    $artifacts = Join-Path $work 'unsigned'
    & (Join-Path $root 'scripts\package-windows.ps1') -Version $Version -StageDirectory $StageDirectory -DistDirectory $artifacts -IsccPath $IsccPath -Commit 1234567
    $manifestPath = Join-Path $artifacts 'release-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.signed -ne $false) { throw 'Unsigned manifest is incorrect.' }
    $manifest.signed = $true
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $names = @("leomoon-sessionguard-$Version-windows-x86-portable.zip","leomoon-sessionguard-$Version-windows-x86-setup.exe",'release-manifest.json')
    $names | Sort-Object | ForEach-Object { '{0} *{1}' -f (Get-FileHash -LiteralPath (Join-Path $artifacts $_) -Algorithm SHA256).Hash.ToLowerInvariant(), $_ } | Set-Content -LiteralPath (Join-Path $artifacts 'SHA256SUMS') -Encoding ASCII
    $failed = $false
    try { & (Join-Path $root 'scripts\verify-windows-package.ps1') -ArtifactDirectory $artifacts -Version $Version } catch { $failed = $_.Exception.Message -match 'signature' }
    if (-not $failed) { throw 'Unsigned files were accepted as signed.' }
    Write-Host 'Unsigned and partial-secret signing checks passed.'
} finally {
    $env:WINDOWS_CERTIFICATE_BASE64 = $oldCertificate
    $env:WINDOWS_CERTIFICATE_PASSWORD = $oldPassword
    if (Test-Path -LiteralPath $work) {
        $resolved = (Resolve-Path -LiteralPath $work).Path
        $allowed = [IO.Path]::GetFullPath((Join-Path $root 'build')) + [IO.Path]::DirectorySeparatorChar
        if ($resolved -eq $work -and $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $work -Recurse -Force }
    }
}
