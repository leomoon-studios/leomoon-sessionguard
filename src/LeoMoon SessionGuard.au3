;~ #NoTrayIcon
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
#pragma compile(FileVersion, 1.3.5.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.3.5.0)

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

OnAutoItExitRegister("_PowerResetState")

;global vars
Global $title = 'LeoMoon SessionGuard'
Global $ver = '1.3.5'
Global $enabled = True
Global $noSleep = True
Global $emu = True
Global $winViz = False
Global $emuVal = 30
Global $ini = @ScriptDir&'\'&$title&'.ini'
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

_iniCheck($ini)

Opt('TrayMenuMode',3)
Opt('TrayAutoPause',0)
Opt("GUICloseOnESC", 0)

TraySetClick(8)

ProcessClose('lmwatchdog.exe')

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
_readHotkey($ini, 'Options', 'Main', $enableTray, 'Guard My Session!', '_guard', '^#.') ;apply main hotkey
_iniToApply($ini)
TraySetState()
;initiate watchdog
;~ _PowerKeepAlive()
if $noSleep Then
    Global $power = _PowerKeepAlive()
Else
    _PowerResetState()
EndIf
$pid = Run('lmwatchdog.exe --mohafez', @ScriptDir, @SW_HIDE)
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
            _guiToIni($ini)
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
        $pid = Run('lmwatchdog.exe --mohafez', @ScriptDir, @SW_HIDE)
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

Func _noSleep()
    if $enabled And $noSleep Then
        $power = _PowerKeepAlive()
    Else
        _PowerResetState()
    EndIf
    ;~ ConsoleWrite($noSleep&@LF)
EndFunc

Func _iniCheck($iniFile)
    If Not FileExists($iniFile) Or _
    IniRead($iniFile, 'Options', 'Main', '') == '' Or _
    IniRead($iniFile, 'Options', 'Emulate Mouse Move', '') == '' Or _
    IniRead($iniFile, 'Options', 'Move Mouse Every', '') == '' Or _
    IniRead($iniFile, 'Options', 'Prevent Sleeping', '') == '' Then
        FileDelete($iniFile)
        IniWrite($iniFile, 'Options', 'Main', '^#.')
        IniWrite($iniFile, 'Options', 'Emulate Mouse Move', '1')
        IniWrite($iniFile, 'Options', 'Move Mouse Every', '30')
        IniWrite($iniFile, 'Options', 'Prevent Sleeping', '1')
    EndIf
    ;double check
    If Not FileExists($iniFile) Then
        _ExtMsgBox(48, 'OK', 'Oops!', $title&' was unable to write settings file at this location:'&@CRLF&'"'&@ScriptDir&'"'&@CRLF, 0)
        Exit
    EndIf
EndFunc

Func _readHotkey($iniFile, $section, $key, $trayItem, $text, $function, $default)
    ;inifile to read
    ;section of the ini
    ;key of the ini
    ;trayitem id to append the new hotkey
    ;trayitem text to append the new hotkey
    ;function to set hotkey
    $appHotkey = IniRead($iniFile, $section, $key, '')
    If $appHotkey == '' Then ;default hotkey if key not found in ini file
        IniWrite($iniFile, $section, $key, $default)
        TrayItemSetText($trayItem, $text&@TAB&_decodeHotkey($default))
    Else
        HotKeySet($appHotkey, $function)
        TrayItemSetText($trayItem, $text&@TAB&_decodeHotkey($appHotkey))
    EndIf
EndFunc

Func _iniToApply($iniFile)
    If IniRead($iniFile, 'Options', 'Emulate Mouse Move', '') == 1 Then
        $emu = True
    Else
        $emu = False
    EndIf
    If IniRead($iniFile, 'Options', 'Prevent Sleeping', '') == 1 Then
        $noSleep = True
    Else
        $noSleep = False
    EndIf
    $emuVal = IniRead($iniFile, 'Options', 'Move Mouse Every', '')
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    ;read main hotkey
    Local $appHotkey = IniRead($iniFile, 'Options', 'Main', '')
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
    If IniRead($iniFile, 'Options', 'Emulate Mouse Move', '') == 1 Then
        GUICtrlSetState($emuCbox, $GUI_CHECKED)
        GUICtrlSetState($secCombo, $GUI_ENABLE)
    Else
        GUICtrlSetState($emuCbox, $GUI_UNCHECKED)
        GUICtrlSetState($secCombo, $GUI_DISABLE)
    EndIf
    _GUICtrlComboBox_SelectString($secCombo, IniRead($iniFile, 'Options', 'Move Mouse Every', '')&' Seconds')
    If RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title) == '' Then
        GUICtrlSetState($startupCbox, $GUI_UNCHECKED)
    Else
        GUICtrlSetState($startupCbox, $GUI_CHECKED)
    EndIf
    If IniRead($iniFile, 'Options', 'Prevent Sleeping', '') == 1 Then
        GUICtrlSetState($nosleepCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($nosleepCbox, $GUI_UNCHECKED)
    EndIf
EndFunc

Func _guiToIni($iniFile) ;reads gui and saves to ini and sets global hotkey only
    ;main hotkey
    Local $oldHotkey = IniRead($iniFile, 'Options', 'Main', '') ;get old hotkey
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($ctrlCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '^'
    If BitAND(GUICtrlRead($altCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '!'
    If BitAND(GUICtrlRead($shiftCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '+'
    If BitAND(GUICtrlRead($winCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '#'
    $appHotkey &= _encodeKey(GUICtrlRead($keyDown))
    IniWrite($iniFile, 'Options', 'Main', $appHotkey) ;write the new hotkey
    HotKeySet($oldHotkey) ;unset old hotkey
    HotKeySet($appHotkey, '_guard') ;set new hotkey
    $txt = _decodeHotkey($appHotkey) ;decode hotkey to text
    TrayItemSetText($enableTray, 'Guard My Session!'&@TAB&$txt) ;change menu entry to new hotkey
    ;rest of settings
    If BitAND(GUICtrlRead($emuCbox), $GUI_CHECKED) == 1 Then
        IniWrite($iniFile, 'Options', 'Emulate Mouse Move', '1')
    Else
        IniWrite($iniFile, 'Options', 'Emulate Mouse Move', '0')
    EndIf
    IniWrite($iniFile, 'Options', 'Move Mouse Every', StringTrimRight(GUICtrlRead($secCombo),8))
    If BitAND(GUICtrlRead($nosleepCbox), $GUI_CHECKED) == 1 Then
        IniWrite($iniFile, 'Options', 'Prevent Sleeping', '1')
    Else
        IniWrite($iniFile, 'Options', 'Prevent Sleeping', '0')
    EndIf
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

Func _decodeHotkey($hotkey)
    Local $decode = ''
    If StringInStr($hotkey,'^') Then $decode &= 'Ctrl + '
    If StringInStr($hotkey,'!') Then $decode &= 'Alt + '
    If StringInStr($hotkey,'+') Then $decode &= 'Shift + '
    If StringInStr($hotkey,'#') Then $decode &= 'Win + '
    $decode &= _decodeKey(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'^',''),'!',''),'+',''),'#','')) ;get the last key
    Return($decode)
EndFunc

Func _encodeKey($k)
    If StringLen($k) > 1 Then
        ;Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9||Numpad 0|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add
        If $k == 'Page Up' Then $k = 'PGUP'
        If $k == 'Page Down' Then $k = 'PGDN'
        If $k == 'Numpad 1' Then $k = 'NUMPAD1'
        If $k == 'Numpad 2' Then $k = 'NUMPAD2'
        If $k == 'Numpad 3' Then $k = 'NUMPAD3'
        If $k == 'Numpad 4' Then $k = 'NUMPAD4'
        If $k == 'Numpad 5' Then $k = 'NUMPAD5'
        If $k == 'Numpad 6' Then $k = 'NUMPAD6'
        If $k == 'Numpad 7' Then $k = 'NUMPAD7'
        If $k == 'Numpad 8' Then $k = 'NUMPAD8'
        If $k == 'Numpad 9' Then $k = 'NUMPAD9'
        If $k == 'Numpad 0' Then $k = 'NUMPAD0'
        If $k == 'Numpad Dot' Then $k = 'NUMPADDOT'
        If $k == 'Numpad Divide' Then $k = 'NUMPADDIV'
        If $k == 'Numpad Multiply' Then $k = 'NUMPADMULT'
        If $k == 'Numpad Subtract' Then $k = 'NUMPADSUB'
        If $k == 'Numpad Add' Then $k = 'NUMPADADD'
        $k = '{'&StringUpper($k)&'}'
    Else
        $k = StringLower($k)
    EndIf
    ;~ ConsoleWrite('encode: '&$k&@LF)
    Return $k
EndFunc

Func _decodeKey($k)
    If StringLen($k) > 1 Then
        ;Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9||Numpad 0|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add
        If $k == '{PGUP}' Then $k = 'Page Up'
        If $k == '{PGDN}' Then $k = 'Page Down'
        If $k == '{NUMPAD1}' Then $k = 'Numpad 1'
        If $k == '{NUMPAD2}' Then $k = 'Numpad 2'
        If $k == '{NUMPAD3}' Then $k = 'Numpad 3'
        If $k == '{NUMPAD4}' Then $k = 'Numpad 4'
        If $k == '{NUMPAD5}' Then $k = 'Numpad 5'
        If $k == '{NUMPAD6}' Then $k = 'Numpad 6'
        If $k == '{NUMPAD7}' Then $k = 'Numpad 7'
        If $k == '{NUMPAD8}' Then $k = 'Numpad 8'
        If $k == '{NUMPAD9}' Then $k = 'Numpad 9'
        If $k == '{NUMPAD0}' Then $k = 'Numpad 0'
        If $k == '{NUMPADDOT}' Then $k = 'Numpad Dot'
        If $k == '{NUMPADDIV}' Then $k = 'Numpad Divide'
        If $k == '{NUMPADMULT}' Then $k = 'Numpad Multiply'
        If $k == '{NUMPADSUB}' Then $k = 'Numpad Subtract'
        If $k == '{NUMPADADD}' Then $k = 'Numpad Add'
        $k = _StringTitleCase($k)
    Else
        $k = StringUpper($k)
    EndIf
    $k = StringReplace(StringReplace($k, '{', ''), '}', '')
    ;~ ConsoleWrite('decode: '&$k&@LF)
    Return $k
EndFunc