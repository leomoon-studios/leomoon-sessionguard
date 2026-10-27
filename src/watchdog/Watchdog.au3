#include-once

; Keep the shutdown-blocking window in its own process and singleton namespace.
Global $g_hWatchdogWindow = 0

Func _WatchdogRun()
    If _Singleton('LeoMoon SessionGuard Watchdog', 1) = 0 Then Return

    $g_hWatchdogWindow = GUICreate('LeoMoon Watchdog', 200, 200)
    GUIRegisterMsg($WM_QUERYENDSESSION, '_WatchdogQueryEndSession')
    _WinAPI_SetProcessShutdownParameters(0x03FF)
    _WinAPI_ShutdownBlockReasonCreate($g_hWatchdogWindow, 'LeoMoon SessionGuard is protecting your session.')
    While 1
        Sleep(5000)
    WEnd
EndFunc

Func _WatchdogQueryEndSession($hWnd, $iMsg, $wParam, $lParam)
    #forceref $iMsg, $wParam, $lParam
    If $hWnd = $g_hWatchdogWindow And _WinAPI_ShutdownBlockReasonQuery($g_hWatchdogWindow) Then Return 0
    Return $GUI_RUNDEFMSG
EndFunc
