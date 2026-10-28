param([Parameter(Mandatory = $true)][string]$Executable)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class SmokeNative {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);
 [DllImport("kernel32.dll")] public static extern bool FreeLibrary(IntPtr module);
 [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern IntPtr LoadImage(IntPtr module, IntPtr name, uint type, int cx, int cy, uint flags);
 [DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr icon);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
 public delegate bool WindowCallback(IntPtr window, IntPtr parameter);
 [DllImport("user32.dll")] public static extern bool EnumWindows(WindowCallback callback, IntPtr parameter);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr window, System.Text.StringBuilder text, int size);
}
'@
$exe = (Resolve-Path -LiteralPath $Executable).Path
$module = [SmokeNative]::LoadLibraryEx($exe, [IntPtr]::Zero, 2)
if ($module -eq [IntPtr]::Zero) { throw 'Unable to load executable resources.' }
try {
    foreach ($id in @(201, 202)) {
        $icon = [SmokeNative]::LoadImage($module, [IntPtr]$id, 1, 0, 0, 0)
        if ($icon -eq [IntPtr]::Zero) { throw "Icon $id could not be loaded." }
        [void][SmokeNative]::DestroyIcon($icon)
    }
} finally { [void][SmokeNative]::FreeLibrary($module) }
$directory = Split-Path -Parent $exe
$ini = Join-Path $directory 'LeoMoon SessionGuard.ini'
if (Test-Path -LiteralPath $ini) { throw 'Build smoke test requires a fresh output directory.' }
$main = Start-Process -FilePath $exe -WorkingDirectory $directory -WindowStyle Hidden -PassThru
$child = $null
try {
    $window = [IntPtr]::Zero
    for ($i = 0; $i -lt 100 -and $window -eq [IntPtr]::Zero; $i++) {
        Start-Sleep -Milliseconds 100
        $main.Refresh()
        if ($main.HasExited) { throw 'The application exited during startup.' }
        $found = [System.Collections.Generic.List[IntPtr]]::new()
        $callback = [SmokeNative+WindowCallback]{ param($handle, $parameter)
            $caption = [System.Text.StringBuilder]::new(512)
            [void][SmokeNative]::GetWindowText($handle, $caption, $caption.Capacity)
            if ($caption.ToString() -eq ('LeoMoon Watchdog ' + $main.Id)) { $found.Add($handle) }
            return $true
        }
        [void][SmokeNative]::EnumWindows($callback, [IntPtr]::Zero)
        if ($found.Count) { $window = $found[0] }
    }
    if ($window -eq [IntPtr]::Zero) { throw 'The watchdog window did not appear.' }
    if (-not (Test-Path -LiteralPath $ini)) { throw 'First launch did not create settings.' }
    [uint32]$childId = 0
    [void][SmokeNative]::GetWindowThreadProcessId($window, [ref]$childId)
    $child = Get-Process -Id $childId -ErrorAction Stop
    if ($child.Path -ne $exe) { throw 'The watchdog is not the same executable.' }
} finally {
    $main.Refresh()
    if (-not $main.HasExited) { Stop-Process -Id $main.Id }
    if ($child) {
        if (-not $child.WaitForExit(5000)) { Stop-Process -Id $child.Id; throw 'Watchdog survived its parent.' }
    }
    if (Test-Path -LiteralPath $ini) { Remove-Item -LiteralPath $ini }
}
Write-Host 'Build smoke checks passed.'
