#NoTrayIcon
;~ #RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Icon_Add=resources\main.ico
#AutoIt3Wrapper_Res_Icon_Add=resources\disabled.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;#pragma compile(UPX, False)
;#pragma compile(x64, False)
#pragma compile(Out, ..\build\LeoMoon SessionGuard.exe)
#pragma compile(Icon, resources\main.ico)
#pragma compile(Compression, 9)
#pragma compile(Comments, This program is freeware.)
#pragma compile(ProductName, LeoMoon SessionGuard)
#pragma compile(FileDescription, LeoMoon SessionGuard)
#pragma compile(FileVersion, 1.3.6.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.3.6.0)

#include <String.au3>
#include <Timers.au3>
;~ #include <Date.au3>
#include <Constants.au3>
#include <StaticConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <WinAPISys.au3>
#include <resources\ExtMsgBox.au3>
;gui includes
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiComboBox.au3>
#include "watchdog/Watchdog.au3"
#include "core/HotkeyCodec.au3"
#include "core/Settings.au3"

; The helper must branch before either the main singleton or tray is created.
If $CmdLine[0] = 1 And $CmdLine[1] = '--watchdog' Then
    _WatchdogRun()
    Exit
EndIf

OnAutoItExitRegister("_PowerResetState")

;global vars
Global $title = 'LeoMoon SessionGuard'
Global $ver = '1.3.6'
Global $enabled = True
Global $noSleep = True
Global $emu = True
Global $winViz = False
Global $emuVal = 30
Global $ini = @ScriptDir&'\'&$title&'.ini'
Global $activeHotkey = ''
;global gui vars
Global $power, $gui, $emuCbox, $secCombo, $saveBtn, $nosleepCbox, $startupCbox, $cancelBtn, $escDummy, $ctrlCbox, $altCbox, $shiftCbox, $winCbox, $keyDown

_ExtMsgBoxSet(0, $SS_RIGHT, -1, -1, 9, "Tahoma")

If Number(_WinAPI_GetVersion()) < 6.0 Then
    _ExtMsgBox(48, 'OK', 'Oops!', 'Require Windows Vista or later.'&@CRLF, 0)
    Exit
EndIf

If _Singleton($title, 1) = 0 Then
    _ExtMsgBox(48, 'OK', 'Oops!', $title&' is currently running.'&@CRLF, 0)
    Exit
EndIf

If Not _SettingsEnsure($ini) Then
    _ExtMsgBox(48, 'OK', 'Settings error', 'Unable to safely write settings in:' & @CRLF & @ScriptDir & @CRLF, 0)
    Exit
EndIf

Opt('TrayMenuMode',3)
Opt('TrayAutoPause',0)
Opt("GUICloseOnESC", 0)

TraySetClick(8)

;~ Global $g_hForm = GUICreate('LMSGForced', 200, 200)
;~ Local $idButton = GUICtrlCreateButton('', 73, 62, 54, 54, $BS_ICON)
;~ GUIRegisterMsg($WM_QUERYENDSESSION, 'WM_QUERYENDSESSION')
;~ _WinAPI_SetProcessShutdownParameters(0x03FF)
;~ ConsoleWrite(_WinAPI_ShutdownBlockReasonCreate($g_hForm, $title&' is on. Exit '&$title&' to restart.')&@LF)
;stop restart
;~ $hForm = GUICreate('LMSGForced', 200, 200)
;~ GUIRegisterMsg(0x0011, 'WM_QUERYENDSESSION')
;~ GUISetState(@SW_SHOW, $hForm)
;~ _WinAPI_SetProcessShutdownParameters(0x03FF)
;~ _WinAPI_ShutdownBlockReasonCreate($hForm, $title&' is on. Exit '&$title&' to restart.')
;menu
$aboutTray = TrayCreateItem($title&' '&$ver)
TrayItemSetState(-1,$TRAY_DISABLE)
TrayCreateItem('')
$enableTray = TrayCreateItem('Guard My Session!')
TrayItemSetState(-1, $TRAY_CHECKED)
TrayCreateItem("")
$settingsTray = TrayCreateItem('Settings...')
TrayCreateItem('')
$leomoonSiteTray = TrayCreateItem("Visit LeoMoon Studios website")
TrayCreateItem('')
$exitTray = TrayCreateItem('Exit')
_readHotkey($ini)
_iniToApply($ini)
TraySetState(1)
;initiate watchdog
;~ _PowerKeepAlive()
if $noSleep Then
    Global $power = _PowerKeepAlive()
Else
    _PowerResetState()
EndIf
$pid = _StartWatchdog()
TraySetToolTip($title&" is enabled.")

While 1
    If $enabled And $emu And StringIsDigit($emuVal) And _Timer_GetIdleTime()/1000 > $emuVal Then
        Local $aPos = MouseGetPos()
        MouseMove($aPos[0],$aPos[1],0)
        ;~ ConsoleWrite('moving mouse to '&$aPos[0]&', '&$aPos[1]&', wait: '&$emuVal&@LF)
    EndIf
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE, $cancelBtn ;, $escDummy
            GUIDelete($gui)
            $winVis = False
        Case $emuCbox
            If BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) == 1 Then
                GUICtrlSetState($secCombo, $GUI_ENABLE)
            Else
                GUICtrlSetState($secCombo, $GUI_DISABLE)
            EndIf
        Case $saveBtn
            If Not _guiToIni($ini) Then ContinueLoop
            _iniToApply($ini)
            If BitAND(GUICtrlRead($startupCbox), $GUI_CHECKED) == 1 Then
                RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title, "REG_SZ", '"'&@ScriptFullPath&'"')
            Else
                RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title)
            EndIf
            ;~ _guard()
            _noSleep()
            GUIDelete($gui)
            $winVis = False
    EndSwitch
    $tMsg = TrayGetMsg()
    Switch $tMsg
        Case $exitTray
            ProcessClose($pid)
            Exit
        Case $TRAY_EVENT_PRIMARYDOUBLE
            _guard()
        Case $enableTray
            _guard()
        Case $settingsTray
            _gui()
        Case $leomoonSiteTray
            ShellExecute('http://leomoon.com', '', '', '', @SW_HIDE)
    EndSwitch
WEnd

Exit

;##########################################################
;########## FUNCTIONS #####################################
;##########################################################
Func _gui()
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    If $winVis == False Then
        $gui = GUICreate($title&" Settings", 410, 250, -1, -1, $WS_SYSMENU)
        GUISetFont(9, 400, 0, "MS Sans Serif")
        $optionsGrp = GUICtrlCreateGroup("Options", 8, 8, 387, 97)
        $emuCbox = GUICtrlCreateCheckbox("Emulate Mouse Move Every", 16, 32, 193, 17)
        ;~ GUICtrlSetState(-1, $GUI_CHECKED)
        $secCombo = GUICtrlCreateCombo("", 216, 28, 153, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, "5 Seconds|10 Seconds|20 Seconds|30 Seconds|40 Seconds|50 Seconds")
        $nosleepCbox = GUICtrlCreateCheckbox("Prevent Sleeping", 16, 56, 353, 17)
        $startupCbox = GUICtrlCreateCheckbox("Start with Windows", 16, 80, 353, 17)
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $hotkeyGrp = GUICtrlCreateGroup("SessionGuard Toggle HotKey", 8, 112, 387, 57)
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

Func _StartWatchdog()
    Local $command = '"' & @ScriptFullPath & '" --watchdog'
    If Not @Compiled Then $command = '"' & @AutoItExe & '" ' & $command
    Return Run($command, @ScriptDir, @SW_HIDE)
EndFunc

Func _noSleep()
    if $enabled And $noSleep Then
        $power = _PowerKeepAlive()
    Else
        _PowerResetState()
    EndIf
    ;~ ConsoleWrite($noSleep&@LF)
EndFunc

Func _readHotkey($iniFile)
    Local $hotkey = IniRead($iniFile, $SETTINGS_SECTION, $SETTING_HOTKEY, $DEFAULT_HOTKEY)
    If HotKeySet($hotkey, '_guard') Then
        $activeHotkey = $hotkey
        TrayItemSetText($enableTray, 'Guard My Session!' & @TAB & _decodeHotkey($hotkey))
    Else
        _ExtMsgBox(48, 'OK', 'Hotkey unavailable', 'The saved shortcut could not be registered. Choose another shortcut in Settings.', 0)
    EndIf
EndFunc

Func _iniToApply($iniFile)
    If IniRead($iniFile, $SETTINGS_SECTION, $SETTING_MOUSE, '') == 1 Then
        $emu = True
    Else
        $emu = False
    EndIf
    If IniRead($iniFile, $SETTINGS_SECTION, $SETTING_SLEEP, '') == 1 Then
        $noSleep = True
    Else
        $noSleep = False
    EndIf
    $emuVal = IniRead($iniFile, $SETTINGS_SECTION, $SETTING_INTERVAL, '')
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
    If RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title) == '' Then
        GUICtrlSetState($startupCbox, $GUI_UNCHECKED)
    Else
        GUICtrlSetState($startupCbox, $GUI_CHECKED)
    EndIf
    If IniRead($iniFile, $SETTINGS_SECTION, $SETTING_SLEEP, '') == 1 Then
        GUICtrlSetState($nosleepCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($nosleepCbox, $GUI_UNCHECKED)
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
    TrayItemSetText($enableTray, 'Guard My Session!' & @TAB & _decodeHotkey($activeHotkey))
    Return True
EndFunc

Func _centerWindow($win)
    $size = WinGetClientSize($win, '')
    Local $y = (@DesktopHeight / 2) - ($size[1] / 2)
    Local $x = (@DesktopWidth / 2) - ($size[0] / 2)
    Return WinMove($win, '', $x, $y)
EndFunc

Func _PowerKeepAlive()
    Local $aRet=DllCall('kernel32.dll','long','SetThreadExecutionState','long',0x80000003)
    If @error Then Return SetError(2,@error,0x80000000)
    ;~ ConsoleWrite('noSleep enabled - '&$aRet[0]&@LF)
    Return $aRet[0] ;previous state (typically 0x80000000 [-2147483648])
EndFunc

Func _PowerResetState()
    ;flag: ES_CONTINUOUS (0x80000000) -> (default) -> used alone, it resets timers & allows regular sleep/power-savings mode
    Local $aRet=DllCall('kernel32.dll','long','SetThreadExecutionState','long',$power)
    If @error Then Return SetError(2,@error,0x80000000)
    ;~ ConsoleWrite('noSleep reset - '&$aRet[0]&@LF)
    Return $aRet[0] ;previous state
EndFunc
