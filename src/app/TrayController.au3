#include-once
Global $enabled = False, $aboutTray, $enableTray, $settingsTray, $leomoonSiteTray, $exitTray

Func _TrayHandleEvent($event)
    Switch $event
        Case $exitTray
            _WatchdogStop()
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
    _TraySetGuardState(False)
    TraySetState(1)
EndFunc

Func _guard()
    If Not $enabled Then
        If Not _WatchdogStart() Then
            _TraySetGuardState(False)
            _ExtMsgBox(48, 'OK', 'Protection unavailable', 'SessionGuard could not start its shutdown protection. Check that the application can run a second instance, then try again.', 0)
            Return
        EndIf
        _TraySetGuardState(True)
    Else
        If Not _WatchdogStop() Then
            _ExtMsgBox(48, 'OK', 'Protection still active', 'SessionGuard could not stop its shutdown protection. Try disabling it again.', 0)
            Return
        EndIf
        _TraySetGuardState(False)
    EndIf
    _noSleep()
EndFunc

Func _TraySetGuardState($state)
    $enabled = $state
    If $state Then
        TraySetToolTip($title & ' is enabled.')
        TraySetIcon(@ScriptFullPath, 201)
        TrayItemSetState($enableTray, $TRAY_CHECKED)
    Else
        TraySetToolTip($title & ' is disabled.')
        TraySetIcon(@ScriptFullPath, 202)
        TrayItemSetState($enableTray, $TRAY_UNCHECKED)
    EndIf
EndFunc

Func _TrayCheckWatchdog()
    If $enabled And Not _WatchdogRunning() Then
        _WatchdogStop()
        _TraySetGuardState(False)
        _noSleep()
        _ExtMsgBox(48, 'OK', 'Protection stopped', 'The shutdown protection stopped unexpectedly. Guarding is now disabled; try enabling it again.', 0)
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
    TrayItemSetState(-1, $TRAY_UNCHECKED)
    TrayCreateItem('')
    $settingsTray = TrayCreateItem('Settings...')
    TrayCreateItem('')
    $leomoonSiteTray = TrayCreateItem('Visit LeoMoon Studios website')
    TrayCreateItem('')
    $exitTray = TrayCreateItem('Exit')
EndFunc
