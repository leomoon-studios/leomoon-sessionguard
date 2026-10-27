#include-once

Global Const $SETTINGS_SECTION = 'Options'
Global Const $SETTING_HOTKEY = 'Main', $SETTING_MOUSE = 'Emulate Mouse Move'
Global Const $SETTING_INTERVAL = 'Move Mouse Every', $SETTING_SLEEP = 'Prevent Sleeping'
Global Const $DEFAULT_HOTKEY = '^#.', $DEFAULT_MOUSE = '1', $DEFAULT_INTERVAL = '30', $DEFAULT_SLEEP = '1'

Func _SettingsValid($key, $value)
    Switch $key
        Case $SETTING_HOTKEY
            Return StringRegExp($value, '^[\^!+#]*(?:[a-zA-Z0-9`\-\[\]\\;'',./]|\{(?:F(?:[1-9]|1[0-2])|SPACE|BACKSPACE|UP|DOWN|LEFT|RIGHT|INSERT|DELETE|HOME|END|PGUP|PGDN|NUMPAD[0-9]|NUMPADDOT|NUMPADDIV|NUMPADMULT|NUMPADSUB|NUMPADADD)\})$')
        Case $SETTING_MOUSE, $SETTING_SLEEP
            Return $value == '0' Or $value == '1'
        Case $SETTING_INTERVAL
            Return StringIsDigit($value) And Number($value) > 0 And Number($value) <= 86400
    EndSwitch
    Return False
EndFunc

; Stage all changes alongside the original so a failed write never truncates it.
Func _SettingsSave($path, $hotkey, $mouse, $interval, $sleep)
    If Not _SettingsValid($SETTING_HOTKEY, $hotkey) Or Not _SettingsValid($SETTING_MOUSE, String($mouse)) Or _
       Not _SettingsValid($SETTING_INTERVAL, String($interval)) Or Not _SettingsValid($SETTING_SLEEP, String($sleep)) Then Return False
    Local $temp = $path & '.' & @AutoItPID & '.tmp'
    If FileExists($temp) Then Return False
    If FileExists($path) And Not FileCopy($path, $temp) Then Return False
    Local $ok = IniWrite($temp, $SETTINGS_SECTION, $SETTING_HOTKEY, $hotkey) And _
        IniWrite($temp, $SETTINGS_SECTION, $SETTING_MOUSE, $mouse) And _
        IniWrite($temp, $SETTINGS_SECTION, $SETTING_INTERVAL, $interval) And _
        IniWrite($temp, $SETTINGS_SECTION, $SETTING_SLEEP, $sleep)
    If $ok Then
        Local $result = DllCall('kernel32.dll', 'bool', 'MoveFileExW', 'wstr', $temp, 'wstr', $path, 'dword', 1)
        $ok = Not @error And $result[0]
    EndIf
    If Not $ok Then FileDelete($temp)
    Return $ok
EndFunc

Func _SettingsEnsure($path)
    Local $keys[4] = [$SETTING_HOTKEY, $SETTING_MOUSE, $SETTING_INTERVAL, $SETTING_SLEEP]
    Local $defaults[4] = [$DEFAULT_HOTKEY, $DEFAULT_MOUSE, $DEFAULT_INTERVAL, $DEFAULT_SLEEP]
    Local $values[4], $changed = False
    For $i = 0 To 3
        $values[$i] = IniRead($path, $SETTINGS_SECTION, $keys[$i], '')
        If Not _SettingsValid($keys[$i], $values[$i]) Then
            $values[$i] = $defaults[$i]
            $changed = True
        EndIf
    Next
    If Not $changed Then Return True
    Return _SettingsSave($path, $values[0], $values[1], $values[2], $values[3])
EndFunc
