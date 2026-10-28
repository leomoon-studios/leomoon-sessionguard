#include-once
Global $g_hWatchdogWindow = 0

Func _WatchdogOpenEvent($name, $access)
    Local $result = DllCall('kernel32.dll', 'handle', 'OpenEventW', 'dword', $access, 'bool', False, 'wstr', $name)
    If @error Then Return 0
    Return $result[0]
EndFunc

Func _WatchdogRun($parentPid, $name)
    If Not StringIsDigit($parentPid) Or Number($parentPid) <= 0 Or $name = '' Then Return
    If _Singleton('LeoMoon SessionGuard Watchdog-' & $parentPid, 1) = 0 Then Return
    Local $parentCall = DllCall('kernel32.dll', 'handle', 'OpenProcess', 'dword', 0x00100000, 'bool', False, 'dword', Number($parentPid))
    If @error Or Not $parentCall[0] Then Return
    Local $parent = $parentCall[0]
    Local $ready = _WatchdogOpenEvent($name & '-ready', 2)
    Local $ack = _WatchdogOpenEvent($name & '-ack', 0x00100000)
    Local $stop = _WatchdogOpenEvent($name & '-stop', 0x00100000)
    Local $started = False
    If $ready And $ack And $stop And _WatchdogWait($parent, 0) = 0x102 Then
        $g_hWatchdogWindow = GUICreate('LeoMoon Watchdog ' & $parentPid, 200, 200)
        If $g_hWatchdogWindow And GUIRegisterMsg($WM_QUERYENDSESSION, '_WatchdogQueryEndSession') And _
            _WinAPI_SetProcessShutdownParameters(0x03FF) And _
            _WinAPI_ShutdownBlockReasonCreate($g_hWatchdogWindow, 'LeoMoon SessionGuard is protecting your session.') Then
            $started = _WatchdogSignal($ready)
        EndIf
    EndIf
    ; If the parent cannot take ownership, do not leave protection running.
    If $started Then
        Local $timer = TimerInit(), $accepted = False
        While TimerDiff($timer) < 5000 And _WatchdogWait($parent, 0) = 0x102 And _WatchdogWait($stop, 0) = 0x102
            If _WatchdogWait($ack, 100) = 0 Then
                $accepted = True
                ExitLoop
            EndIf
        WEnd
        While $accepted And _WatchdogWait($parent, 0) = 0x102 And _WatchdogWait($stop, 0) = 0x102
            Sleep(100)
        WEnd
    EndIf
    If $g_hWatchdogWindow Then
        _WinAPI_ShutdownBlockReasonDestroy($g_hWatchdogWindow)
        GUIDelete($g_hWatchdogWindow)
    EndIf
    _WatchdogCloseHandle($ready)
    _WatchdogCloseHandle($ack)
    _WatchdogCloseHandle($stop)
    _WatchdogCloseHandle($parent)
EndFunc

Func _WatchdogQueryEndSession($hWnd, $iMsg, $wParam, $lParam)
    #forceref $iMsg, $wParam, $lParam
    If $hWnd = $g_hWatchdogWindow And _WinAPI_ShutdownBlockReasonQuery($g_hWatchdogWindow) Then Return 0
    Return $GUI_RUNDEFMSG
EndFunc
