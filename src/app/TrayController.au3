#include-once
Global $enabled = True, $pid = 0, $aboutTray, $enableTray, $settingsTray, $leomoonSiteTray, $exitTray

Func _TrayHandleEvent($event)
    Switch $event
        Case $exitTray
            ProcessClose($pid)
            Return True
        Case $TRAY_EVENT_PRIMARYDOUBLE, $enableTray
            _guard()
        Case $settingsTray
            _gui()
        Case $leomoonSiteTray
            ShellExecute('http://leomoon.com', '', '', '', @SW_HIDE)
    EndSwitch
    Return False
EndFunc

Func _TraySetHotkey($hotkey)
    TrayItemSetText($enableTray, 'Guard My Session!' & @TAB & _decodeHotkey($hotkey))
EndFunc

Func _TrayShow()
    TraySetToolTip($title & ' is enabled.')
    TraySetState(1)
EndFunc

Func _guard()
    If Not $enabled Then ;enable it
        $pid = _StartWatchdog()
        TraySetToolTip($title&" is enabled.")
        TraySetIcon(@ScriptFullPath, 201)
        TrayItemSetState($enableTray,$TRAY_CHECKED)
        $enabled = True
        _noSleep()
        ;~ ConsoleWrite('sessionguard enabled'&@LF)
    Else
        ProcessClose($pid)
        TraySetToolTip($title&" is disabled.")
        TraySetIcon(@ScriptFullPath, 202)
        TrayItemSetState($enableTray,$TRAY_UNCHECKED)
        $enabled = False
        _noSleep()
        ;~ ConsoleWrite('sessionguard disabled'&@LF)
    EndIf
EndFunc

Func _readHotkey($iniFile)
    Local $hotkey = IniRead($iniFile, $SETTINGS_SECTION, $SETTING_HOTKEY, $DEFAULT_HOTKEY)
    If HotKeySet($hotkey, '_guard') Then
        $activeHotkey = $hotkey
        _TraySetHotkey($hotkey)
    Else
        _ExtMsgBox(48, 'OK', 'Hotkey unavailable', 'The saved shortcut could not be registered. Choose another shortcut in Settings.', 0)
    EndIf
EndFunc


Func _TrayCreate()
    Opt('TrayMenuMode', 3)
    Opt('TrayAutoPause', 0)
    Opt('GUICloseOnESC', 0)
    TraySetClick(8)
    $aboutTray = TrayCreateItem($title & ' ' & $ver)
    TrayItemSetState(-1, $TRAY_DISABLE)
    TrayCreateItem('')
    $enableTray = TrayCreateItem('Guard My Session!')
    TrayItemSetState(-1, $TRAY_CHECKED)
    TrayCreateItem('')
    $settingsTray = TrayCreateItem('Settings...')
    TrayCreateItem('')
    $leomoonSiteTray = TrayCreateItem('Visit LeoMoon Studios website')
    TrayCreateItem('')
    $exitTray = TrayCreateItem('Exit')
EndFunc
