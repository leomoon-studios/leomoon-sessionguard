#include "../src/core/HotkeyCodec.au3"
#include "../src/core/Settings.au3"

Global $failures = 0
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
FileDelete($file)
DirRemove($dir)
ConsoleWrite('Settings failures: ' & $failures & @CRLF)
Exit $failures

Func _unused()
EndFunc
