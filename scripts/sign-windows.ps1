[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$encoded = $env:WINDOWS_CERTIFICATE_BASE64
$password = $env:WINDOWS_CERTIFICATE_PASSWORD
if ([string]::IsNullOrWhiteSpace($encoded) -and [string]::IsNullOrEmpty($password)) { return }
if ([string]::IsNullOrWhiteSpace($encoded) -or [string]::IsNullOrEmpty($password)) { throw 'Both Windows signing secrets are required.' }
$exe = (Resolve-Path -LiteralPath $Path).Path
$signtool = Get-Command signtool.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $signtool) {
    $kits = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    if (Test-Path -LiteralPath $kits) {
        $signtool = Get-ChildItem -LiteralPath $kits -Filter signtool.exe -File -Recurse | Where-Object { $_.Directory.Name -eq 'x64' } | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}
if (-not $signtool) { throw 'Windows SDK signtool.exe not found.' }
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('sessionguard-sign-' + [guid]::NewGuid().ToString('N') + '.pfx')
$bytes = $null
try {
    try { $bytes = [Convert]::FromBase64String($encoded) } catch { throw 'The signing certificate is not valid base64.' }
    [IO.File]::WriteAllBytes($temporary, $bytes)
    & $signtool sign /fd SHA256 /f $temporary /p $password /tr 'http://timestamp.digicert.com' /td SHA256 $exe
    if ($LASTEXITCODE -ne 0) { throw "Signing failed for $([IO.Path]::GetFileName($exe))." }
    $signature = Get-AuthenticodeSignature -LiteralPath $exe
    if ($signature.Status -ne 'Valid' -or -not $signature.TimeStamperCertificate) { throw "Signature or timestamp verification failed for $([IO.Path]::GetFileName($exe))." }
} finally {
    if ($bytes) { [Array]::Clear($bytes, 0, $bytes.Length) }
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
}
