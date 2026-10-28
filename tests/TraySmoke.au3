#NoTrayIcon
#include <Constants.au3>
#include <GUIConstantsEx.au3>

Global $title = 'Test SessionGuard', $ver = 'test', $activeHotkey = ''
Global $SETTINGS_SECTION = 'Options', $SETTING_HOTKEY = 'Main', $DEFAULT_HOTKEY = '^!1'
Global $canStart = False, $canStop = True, $running = False, $warnings = 0, $powerUpdates = 0, $failures = 0
#include "../src/app/TrayController.au3"

Func _WatchdogStart()
    $running = $canStart
    Return $canStart
EndFunc
Func _WatchdogStop()
    If $canStop Then $running = False
    Return $canStop
EndFunc
Func _WatchdogRunning()
    Return $running
EndFunc
Func _noSleep()
    $powerUpdates += 1
EndFunc
Func _ExtMsgBox($icon, $buttons, $caption, $message, $timeout)
    #forceref $icon, $buttons, $caption, $message, $timeout
    $warnings += 1
EndFunc
Func _decodeHotkey($value)
    Return $value
EndFunc
Func _gui()
EndFunc
Func _assert($condition, $message)
    If Not $condition Then
        ConsoleWrite('FAIL: ' & $message & @CRLF)
        $failures += 1
    EndIf
EndFunc

_TrayCreate()
_TrayShow()
_guard()
_assert(Not $enabled And $warnings = 1, 'failed start leaves guarding disabled')
$canStart = True
_guard()
_assert($enabled And $running, 'successful start enables guarding')
$canStop = False
_guard()
_assert($enabled And $running And $warnings = 2, 'failed stop keeps guarding enabled')
$canStop = True
$running = False
_TrayCheckWatchdog()
_assert(Not $enabled And $warnings = 3 And $powerUpdates = 2, 'unexpected exit disables guarding and resets power')
ConsoleWrite('Tray failures: ' & $failures & @CRLF)
Exit $failures
