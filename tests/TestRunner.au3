#include "../src/core/HotkeyCodec.au3"
#include "../src/core/Settings.au3"
#include "../src/core/PowerState.au3"
#include "../src/core/IdleGuard.au3"

Global $failures = 0
Global $fakePowerCalls = 0, $fakePowerFlags = 0, $fakePowerFails = False, $fakeWarnings = 0
Global $fakeIdle = 0, $fakeIdleReads = 0, $fakeMoves = 0, $fakeIdleFails = False, $fakeMoveFails = False
Func _assert($condition, $message)
    If Not $condition Then
        ConsoleWrite('FAIL: ' & $message & @CRLF)
        $failures += 1
    EndIf
EndFunc

Local $dir = @TempDir & '\SessionGuard-settings-test-' & @AutoItPID
DirCreate($dir)
Local $file = $dir & '\settings.ini'
_assert(_SettingsEnsure($file), 'create defaults')
_assert(IniRead($file, 'Options', 'Main', '') == '^#.', 'default shortcut')
IniWrite($file, 'Options', 'Main', '^!1')
IniWrite($file, 'Options', 'Emulate Mouse Move', '0')
IniWrite($file, 'Options', 'Move Mouse Every', 'bad')
IniWrite($file, 'Other', 'Keep', 'yes')
_assert(_SettingsEnsure($file), 'repair malformed field')
_assert(IniRead($file, 'Options', 'Main', '') == '^!1', 'preserve shortcut')
_assert(IniRead($file, 'Options', 'Emulate Mouse Move', '') == '0', 'preserve valid field')
_assert(IniRead($file, 'Options', 'Move Mouse Every', '') == '30', 'repair interval')
_assert(IniRead($file, 'Other', 'Keep', '') == 'yes', 'preserve unrelated settings')
_assert(Not _SettingsSave($file, '^!1', 0, 'invalid', 0), 'reject invalid save')
_assert(IniRead($file, 'Options', 'Move Mouse Every', '') == '30', 'failed save preserves file')
_assert(Not _SettingsEnsure($dir & '\missing\settings.ini'), 'unwritable path fails')
_assert(_SettingsSave($file, '^!1', 1, 5, 0), 'save valid settings')
_assert(IniRead($file, 'Options', 'Move Mouse Every', '') == '5', 'saved interval')
FileSetAttrib($file, '+R')
_assert(Not _SettingsSave($file, '^!2', 0, 10, 1), 'read-only settings reject save')
_assert(IniRead($file, 'Options', 'Main', '') == '^!1', 'read-only file preserved')
FileSetAttrib($file, '-R')

Local $keys = StringSplit('F1|F12|A|.|Page Up|Page Down|Space|Numpad 1|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add', '|')
For $i = 1 To $keys[0]
    Local $encoded = _encodeKey($keys[$i])
    _assert(StringUpper(_decodeKey($encoded)) == StringUpper($keys[$i]), 'round trip ' & $keys[$i])
    _assert(_SettingsValid($SETTING_HOTKEY, '^!' & $encoded), 'validate ' & $keys[$i])
Next
_assert(Not _SettingsValid($SETTING_HOTKEY, '^!'), 'reject missing key')

; Register a temporary system hotkey under a different window to create a conflict.
Local $reservation = DllCall('user32.dll', 'bool', 'RegisterHotKey', 'hwnd', 0, 'int', 17001, 'uint', 7, 'uint', 0x7B)
If Not @error And $reservation[0] Then
    _assert(HotKeySet('^!+{F11}', '_unused'), 'register previous hotkey')
    _assert(Not HotKeySet('^!+{F12}', '_unused'), 'detect conflicting hotkey')
    Local $previous = DllCall('user32.dll', 'bool', 'RegisterHotKey', 'hwnd', 0, 'int', 17002, 'uint', 7, 'uint', 0x7A)
    _assert(Not @error And Not $previous[0], 'previous shortcut remains registered')
    If Not @error And $previous[0] Then DllCall('user32.dll', 'bool', 'UnregisterHotKey', 'hwnd', 0, 'int', 17002)
    HotKeySet('^!+{F11}')
    DllCall('user32.dll', 'bool', 'UnregisterHotKey', 'hwnd', 0, 'int', 17001)
Else
    ConsoleWrite('SKIP: could not reserve test hotkey' & @CRLF)
EndIf

; All power and input boundaries below are fakes; the cursor is never moved.
$g_powerCall = '_FakePower'
_assert(_PowerSet(False) And $fakePowerCalls = 0, 'no restore without ownership')
$fakePowerFails = True
_assert(Not _PowerSet(True) And Not $g_powerOwned, 'failed request is not owned')
$fakePowerFails = False
_assert(_PowerSet(True) And $g_powerOwned, 'acquire power request')
Local $callsAfterAcquire = $fakePowerCalls
_assert(_PowerSet(True) And $fakePowerCalls = $callsAfterAcquire, 'repeated enable preserves original state')
$fakePowerFails = True
_assert(Not _PowerSet(False) And $g_powerOwned, 'failed restore retains ownership')
$fakePowerFails = False
_assert(_PowerSet(False) And Not $g_powerOwned And $fakePowerFlags = 0x80000002, 'restore previous state')
_assert(_PowerSet(True), 'reacquire for exit')
_PowerCleanup()
_assert(Not $g_powerOwned And $fakeWarnings = 0, 'exit cleanup releases request')
_assert(_PowerSet(True), 'reacquire for failed exit')
$fakePowerFails = True
_PowerCleanup()
_assert($g_powerOwned And $fakeWarnings = 1, 'exit cleanup reports failure')
$fakePowerFails = False
_assert(_PowerSet(False), 'retry failed cleanup')

$g_idleRead = '_FakeIdleRead'
$g_idleMove = '_FakeIdleMove'
_assert(_IdleCheck(False, True, 5) And $fakeIdleReads = 0 And $fakeMoves = 0, 'disabled guard does not read or move')
_assert(_IdleCheck(True, False, 5) And $fakeIdleReads = 0, 'disabled emulation does not read or move')
_assert(Not _IdleCheck(True, True, 0), 'zero interval rejected')
_assert(Not _IdleCheck(True, True, 86401), 'oversized interval rejected')
$fakeIdle = 4999
_assert(_IdleCheck(True, True, 5) And $fakeMoves = 0, 'below interval does not move')
$fakeIdle = 5000
_assert(_IdleCheck(True, True, 5) And $fakeMoves = 1, 'interval boundary moves once')
$fakeIdleFails = True
_assert(Not _IdleCheck(True, True, 5) And $fakeMoves = 1, 'idle read failure reported')
$fakeIdleFails = False
$fakeMoveFails = True
_assert(Not _IdleCheck(True, True, 5), 'mouse move failure reported')

FileDelete($file)
DirRemove($dir)
ConsoleWrite('Test failures: ' & $failures & @CRLF)
Exit $failures

Func _unused()
EndFunc

Func _FakePower($flags)
    $fakePowerCalls += 1
    $fakePowerFlags = $flags
    If $fakePowerFails Then Return SetError(1, 0, 0)
    Return 0x80000002
EndFunc

Func _FakeIdleRead()
    $fakeIdleReads += 1
    If $fakeIdleFails Then Return SetError(1, 0, 0)
    Return $fakeIdle
EndFunc

Func _FakeIdleMove()
    $fakeMoves += 1
    If $fakeMoveFails Then Return SetError(1, 0, False)
    Return True
EndFunc

Func _ExtMsgBox($icon, $buttons, $caption, $message, $timeout)
    #forceref $icon, $buttons, $caption, $message, $timeout
    $fakeWarnings += 1
EndFunc
