#NoTrayIcon
#include <Constants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiComboBox.au3>
#include "../src/resources/ExtMsgBox.au3"
#include "../src/core/AppConstants.au3"
#include "../src/core/Settings.au3"
#include "../src/core/HotkeyCodec.au3"
#include "../src/app/StartupRegistration.au3"

Global $title = $APP_NAME, $ver = $APP_VERSION, $activeHotkey = ''
Global $ini = @TempDir & '\SessionGuard-desktop-test-' & @AutoItPID & '.ini'
Global $failures = 0
#include "../src/app/TrayController.au3"
#include "../src/gui/SettingsWindow.au3"

Func _assert($condition, $message)
    If Not $condition Then
        ConsoleWrite('FAIL: ' & $message & @CRLF)
        $failures += 1
    EndIf
EndFunc

; Simulate guard lifecycle with a process owned by this test, not the real watchdog.
Func _StartWatchdog()
    Return Run(@SystemDir & '\ping.exe -n 30 127.0.0.1', @TempDir, @SW_HIDE)
EndFunc
Func _noSleep()
EndFunc

_assert(_SettingsSave($ini, '^!+{F11}', 0, 30, 0), 'create isolated settings')
_TrayCreate()
TraySetState(1)
_gui()
Local $first = $gui
_gui()
_assert($gui = $first And $winVis, 'reopen activates existing window')
GUICtrlSetState($emuCbox, $GUI_CHECKED)
_SettingsWindowUpdateMouse()
_assert(BitAND(GUICtrlGetState($secCombo), $GUI_ENABLE) <> 0, 'mouse interval enabled')
_SettingsWindowClose()
_assert(Not $winVis, 'close window')
_gui()
_assert(BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) = 0, 'cancel preserves settings')
GUICtrlSetState($emuCbox, $GUI_CHECKED)
_assert(_guiToIni($ini), 'save window settings')
_assert(IniRead($ini, 'Options', 'Emulate Mouse Move', '') = '1', 'saved option')
_SettingsWindowClose()
_gui()
_assert(BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) = 1, 'reopen loads saved settings')
_SettingsWindowClose()
If $activeHotkey <> '' Then HotKeySet($activeHotkey)

; Exercise tray toggles with a private child process.
$pid = _StartWatchdog()
_assert(ProcessExists($pid), 'test child started')
_TrayHandleEvent($enableTray)
ProcessWaitClose($pid, 2)
_assert(Not $enabled And Not ProcessExists($pid), 'tray disables guard and stops child')
_TrayHandleEvent($TRAY_EVENT_PRIMARYDOUBLE)
_assert($enabled And ProcessExists($pid), 'double click enables guard and starts child')
_assert(_TrayHandleEvent($exitTray), 'exit event')
ProcessWaitClose($pid, 2)
_assert(Not ProcessExists($pid), 'exit stops child')

Local $key = 'HKEY_CURRENT_USER\Software\SessionGuardDesktopTest-' & @AutoItPID
_assert(_StartupSet(True, $key, 'Test'), 'startup write')
_assert(_StartupIsEnabled($key, 'Test'), 'startup read')
_assert(_StartupSet(False, $key, 'Test'), 'startup delete')
_assert(Not _StartupIsEnabled($key, 'Test'), 'startup disabled')
_assert(_StartupSet(False, $key, 'Test'), 'startup delete when absent')
_assert(Not _StartupSet(True, 'HKEY_INVALID\SessionGuard', 'Test'), 'startup write failure')
RegDelete($key)
FileDelete($ini)
ConsoleWrite('Desktop failures: ' & $failures & @CRLF)
Exit $failures
