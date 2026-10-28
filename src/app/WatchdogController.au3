#include-once

Global $g_watchdogProcess = 0, $g_watchdogStop = 0, $g_watchdogPid = 0

Func _WatchdogCloseHandle($handle)
    If $handle Then DllCall('kernel32.dll', 'bool', 'CloseHandle', 'handle', $handle)
EndFunc

Func _WatchdogWait($handle, $timeout)
    Local $result = DllCall('kernel32.dll', 'dword', 'WaitForSingleObject', 'handle', $handle, 'dword', $timeout)
    If @error Then Return 0xFFFFFFFF
    Return $result[0]
EndFunc

Func _WatchdogEvent($name)
    Local $result = DllCall('kernel32.dll', 'handle', 'CreateEventW', 'ptr', 0, 'bool', True, 'bool', False, 'wstr', $name)
    If @error Then Return 0
    Return $result[0]
EndFunc

Func _WatchdogSignal($event)
    Local $result = DllCall('kernel32.dll', 'bool', 'SetEvent', 'handle', $event)
    If @error Then Return False
    Return $result[0] <> 0
EndFunc

; Optional path arguments allow lifecycle tests to launch an isolated build.
Func _WatchdogStart($script = @ScriptFullPath, $interpreter = '')
    If $g_watchdogProcess Then Return False
    If Not @Compiled And $script = @ScriptFullPath And $interpreter = '' Then $interpreter = @AutoItExe
    Local $name = 'Local\LeoMoonSessionGuard-' & @AutoItPID & '-' & Hex(Random(0, 0x7FFFFFFF, 1), 8)
    Local $ready = _WatchdogEvent($name & '-ready')
    Local $ack = _WatchdogEvent($name & '-ack')
    $g_watchdogStop = _WatchdogEvent($name & '-stop')
    If Not $ready Or Not $ack Or Not $g_watchdogStop Then
        _WatchdogCloseHandle($ready)
        _WatchdogCloseHandle($ack)
        _WatchdogStop()
        Return False
    EndIf
    Local $command = '"' & $script & '" --watchdog ' & @AutoItPID & ' "' & $name & '"'
    If $interpreter <> '' Then $command = '"' & $interpreter & '" ' & $command
    Local $workingDir = @ScriptDir, $separator = StringInStr($script, '\', 0, -1)
    If $separator > 0 Then $workingDir = StringLeft($script, $separator - 1)
    $g_watchdogPid = Run($command, $workingDir, @SW_HIDE)
    If $g_watchdogPid Then
        Local $opened = DllCall('kernel32.dll', 'handle', 'OpenProcess', 'dword', 0x00100001, 'bool', False, 'dword', $g_watchdogPid)
        If Not @error Then $g_watchdogProcess = $opened[0]
    EndIf
    Local $success = False, $timer = TimerInit()
    While $g_watchdogProcess And TimerDiff($timer) < 5000
        If _WatchdogWait($g_watchdogProcess, 0) <> 0x102 Then ExitLoop
        If _WatchdogWait($ready, 50) = 0 Then
            If _WatchdogWait($g_watchdogProcess, 0) = 0x102 Then $success = _WatchdogSignal($ack)
            ExitLoop
        EndIf
    WEnd
    _WatchdogCloseHandle($ready)
    _WatchdogCloseHandle($ack)
    If Not $success Then _WatchdogStop()
    Return $success
EndFunc

Func _WatchdogRunning()
    Return $g_watchdogProcess <> 0 And _WatchdogWait($g_watchdogProcess, 0) = 0x102
EndFunc

Func _WatchdogStop()
    If $g_watchdogStop Then _WatchdogSignal($g_watchdogStop)
    If $g_watchdogProcess Then
        Local $status = _WatchdogWait($g_watchdogProcess, 3000)
        If $status = 0x102 Then
            DllCall('kernel32.dll', 'bool', 'TerminateProcess', 'handle', $g_watchdogProcess, 'uint', 1)
            $status = _WatchdogWait($g_watchdogProcess, 3000)
        EndIf
        ; Retain the handle if the process could not be confirmed stopped.
        If $status <> 0 Then Return False
    EndIf
    _WatchdogCloseHandle($g_watchdogProcess)
    _WatchdogCloseHandle($g_watchdogStop)
    $g_watchdogProcess = 0
    $g_watchdogStop = 0
    $g_watchdogPid = 0
    Return True
EndFunc
