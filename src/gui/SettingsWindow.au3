#include-once
Global $gui, $winVis = False, $emuCbox, $secCombo, $saveBtn, $nosleepCbox, $startupCbox, $cancelBtn, $ctrlCbox, $altCbox, $shiftCbox, $winCbox, $keyDown

Func _gui()
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    If $winVis == False Then
        $gui = GUICreate($title&" Settings", 410, 250, -1, -1, $WS_SYSMENU)
        GUISetFont(9, 400, 0, "MS Sans Serif")
        GUICtrlCreateGroup("Options", 8, 8, 387, 97)
        $emuCbox = GUICtrlCreateCheckbox("Emulate Mouse Move Every", 16, 32, 193, 17)
        ;~ GUICtrlSetState(-1, $GUI_CHECKED)
        $secCombo = GUICtrlCreateCombo("", 216, 28, 153, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, "5 Seconds|10 Seconds|20 Seconds|30 Seconds|40 Seconds|50 Seconds")
        $nosleepCbox = GUICtrlCreateCheckbox("Prevent Sleeping", 16, 56, 353, 17)
        $startupCbox = GUICtrlCreateCheckbox("Start with Windows", 16, 80, 353, 17)
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        GUICtrlCreateGroup("SessionGuard Toggle HotKey", 8, 112, 387, 57)
        $ctrlCbox = GUICtrlCreateCheckbox("Ctrl", 16, 136, 57, 17)
        $shiftCbox = GUICtrlCreateCheckbox("Shift", 144, 136, 57, 17)
        $winCbox = GUICtrlCreateCheckbox("Win", 208, 136, 57, 17)
        $altCbox = GUICtrlCreateCheckbox("Alt", 80, 136, 57, 17)
        $keyDown = GUICtrlCreateCombo("", 272, 134, 113, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, "F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|`|1|2|3|4|5|6|7|8|9|0|-|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|'|,|.|/|Space|Backspace|Up|Down|Left|Right|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add")
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $saveBtn = GUICtrlCreateButton("Save", 8, 176, 187, 33)
        $cancelBtn = GUICtrlCreateButton("Cancel", 200, 176, 195, 33)
        ;edit ui
        GUISetIcon(@ScriptFullPath, 201)
        _GUICtrlComboBox_SetCurSel($secCombo, 3)
        ;setup esc to hide gui
        ;~ $escDummy = GUICtrlCreateDummy()
        ;~ Local $aAccelKeys[1][2] = [["{ESCAPE}", $escDummy]]
        ;~ GUISetAccelerators($aAccelKeys)
        _iniToGui($ini) ;set gui from ini file
        GUISetState(@SW_SHOW, $gui)
        WinActivate($gui)
        $winVis = True
    Else
        WinActivate($gui)
    EndIf
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    ;read main hotkey
    Local $appHotkey = IniRead($iniFile, $SETTINGS_SECTION, $SETTING_HOTKEY, '')
    Local $k = StringUpper(StringReplace(StringReplace(StringReplace(StringReplace($appHotkey,'^',''),'!',''),'+',''),'#',''))
    $k = _decodeKey($k)
    If StringInStr($appHotkey,'^') Then
        GUICtrlSetState($ctrlCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($ctrlCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'!') Then
        GUICtrlSetState($altCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($altCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'+') Then
        GUICtrlSetState($shiftCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($shiftCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'#') Then
        GUICtrlSetState($winCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($winCbox, $GUI_UNCHECKED)
    EndIf
    _GUICtrlComboBox_SelectString($keyDown, StringUpper($k))
    ;rest of settings
    If IniRead($iniFile, $SETTINGS_SECTION, $SETTING_MOUSE, '') == 1 Then
        GUICtrlSetState($emuCbox, $GUI_CHECKED)
        GUICtrlSetState($secCombo, $GUI_ENABLE)
    Else
        GUICtrlSetState($emuCbox, $GUI_UNCHECKED)
        GUICtrlSetState($secCombo, $GUI_DISABLE)
    EndIf
    _GUICtrlComboBox_SelectString($secCombo, IniRead($iniFile, $SETTINGS_SECTION, $SETTING_INTERVAL, '')&' Seconds')
    If _StartupIsEnabled() Then
        GUICtrlSetState($startupCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($startupCbox, $GUI_UNCHECKED)
    EndIf
    If IniRead($iniFile, $SETTINGS_SECTION, $SETTING_SLEEP, '') == 1 Then
        GUICtrlSetState($nosleepCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($nosleepCbox, $GUI_UNCHECKED)
    EndIf
EndFunc

Func _SettingsWindowClose()
    If $winVis Then GUIDelete($gui)
    $winVis = False
EndFunc

Func _SettingsWindowUpdateMouse()
    If BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) = 1 Then
        GUICtrlSetState($secCombo, $GUI_ENABLE)
    Else
        GUICtrlSetState($secCombo, $GUI_DISABLE)
    EndIf
EndFunc

Func _guiToIni($iniFile) ;reads gui and saves to ini and sets global hotkey only
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($ctrlCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '^'
    If BitAND(GUICtrlRead($altCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '!'
    If BitAND(GUICtrlRead($shiftCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '+'
    If BitAND(GUICtrlRead($winCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '#'
    $appHotkey &= _encodeKey(GUICtrlRead($keyDown))
    Local $interval = StringTrimRight(GUICtrlRead($secCombo), 8)
    Local $mouse = Number(BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) == 1)
    Local $sleep = Number(BitAND(GUICtrlRead($nosleepCbox), $GUI_CHECKED) == 1)
    If Not _SettingsValid($SETTING_HOTKEY, $appHotkey) Or Not _SettingsValid($SETTING_INTERVAL, $interval) Then
        _ExtMsgBox(48, 'OK', 'Invalid settings', 'Choose a valid shortcut and mouse interval.', 0)
        Return False
    EndIf
    Local $changed = ($appHotkey <> $activeHotkey)
    If $changed And Not HotKeySet($appHotkey, '_guard') Then
        _ExtMsgBox(48, 'OK', 'Hotkey unavailable', 'That shortcut could not be registered. The previous shortcut is still active.', 0)
        Return False
    EndIf
    If Not _SettingsSave($iniFile, $appHotkey, $mouse, $interval, $sleep) Then
        If $changed Then HotKeySet($appHotkey)
        _ExtMsgBox(48, 'OK', 'Settings error', 'Settings could not be saved. The previous settings and shortcut have been kept.', 0)
        Return False
    EndIf
    If $changed And $activeHotkey <> '' Then HotKeySet($activeHotkey)
    $activeHotkey = $appHotkey
    _TraySetHotkey($activeHotkey)
    Return True
EndFunc
