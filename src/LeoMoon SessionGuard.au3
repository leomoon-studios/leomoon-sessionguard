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
#pragma compile(FileVersion, 1.3.0.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.3.0.0)

#include <Timers.au3>
#include <Date.au3>
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
Global $ver = '1.3'
Global $enabled = True
Global $emu = True
Global $emuVal = 30
Global $ini = @ScriptDir&'\'&$title&'.ini'
;global gui vars
Global $gui, $emuCbox, $secCombo, $saveBtn, $startupCbox, $cancelBtn, $escDummy, $ctrlCbox, $altCbox, $shiftCbox, $winCbox, $keyDown

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
_readHotkey($ini, 'Options', 'Main', $enableTray, 'Guard My Session!', '_guard', '^#1') ;apply main hotkey
_iniToApply($ini)
TraySetState()
;initiate watchdog
_PowerKeepAlive()
$pid = Run('lmwatchdog.exe --mohafez', @ScriptDir, @SW_HIDE)
TraySetToolTip($title&" is enabled.")

While 1
    If $enabled And $emu And StringIsDigit($emuVal) And _Timer_GetIdleTime()/1000 > $emuVal Then
        Local $aPos = MouseGetPos()
        MouseMove($aPos[0],$aPos[1],0)
        ;~ ConsoleWrite('moving the mouse to '&$aPos[0]&', '&$aPos[1]&', wait: '&$emuVal&@LF)
    EndIf
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE, $cancelBtn ;, $escDummy
            GUIDelete($gui)
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
            GUIDelete($gui)
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
			ShellExecute('http://leomoon.com')
    EndSwitch
WEnd

Exit

;##########################################################
;########## FUNCTIONS #####################################
;##########################################################
Func _gui()
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $gui = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    $gui = GUICreate($title&" Settings", 386+7, 202+29, -1, -1, $WS_SYSMENU)
    GUISetIcon(@ScriptFullPath, 201)
    GUISetFont(9, 400, 0, "MS Sans Serif")
    $optionsGrp = GUICtrlCreateGroup("Options", 8, 8, 371, 81)
    $startupCbox = GUICtrlCreateCheckbox("Start with Windows", 16, 56, 273, 17)
    $emuCbox = GUICtrlCreateCheckbox("Emulate Mouse Move Every", 16, 32, 193, 17)
    GUICtrlSetState(-1, $GUI_CHECKED)
    $secCombo = GUICtrlCreateCombo("", 216, 28, 153, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
    GUICtrlSetData(-1, "5 Seconds|10 Seconds|20 Seconds|30 Seconds|40 Seconds|50 Seconds")
    _GUICtrlComboBox_SetCurSel($secCombo, 3)
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $hotkeyGrp = GUICtrlCreateGroup("SessionGuard Toggle HotKey", 8, 96, 371, 57)
    $ctrlCbox = GUICtrlCreateCheckbox("Ctrl", 16, 120, 57, 17)
    $shiftCbox = GUICtrlCreateCheckbox("Shift", 144, 120, 57, 17)
    $winCbox = GUICtrlCreateCheckbox("Win", 208, 120, 57, 17)
    $altCbox = GUICtrlCreateCheckbox("Alt", 80, 120, 57, 17)
    $keyDown = GUICtrlCreateCombo("", 272, 118, 97, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
    GUICtrlSetData(-1, "`|1|2|3|4|5|6|7|8|9|0|-|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|"&Chr(39)&"|,|.|/")
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $saveBtn = GUICtrlCreateButton("Save", 8, 160, 179, 33)
    $cancelBtn = GUICtrlCreateButton("Cancel", 192, 160, 187, 33)
    ;setup esc to hide gui
    ;~ $escDummy = GUICtrlCreateDummy()
    ;~ Local $aAccelKeys[1][2] = [["{ESCAPE}", $escDummy]]
    ;~ GUISetAccelerators($aAccelKeys)
    _iniToGui($ini) ;set gui from ini file
    GUISetState(@SW_SHOW, $gui)
    WinActivate($gui)
EndFunc

Func _guard()
    If Not $enabled Then ;enable it
        _PowerKeepAlive()
        $pid = Run('lmwatchdog.exe --mohafez', @ScriptDir, @SW_HIDE)
        TraySetToolTip($title&" is enabled.")
        TraySetIcon(@ScriptFullPath, 201)
        TrayItemSetState($enableTray,$TRAY_CHECKED)
        $enabled = True
    Else
        _PowerResetState()
        ProcessClose($pid)
		TraySetToolTip($title&" is disabled.")
        TraySetIcon(@ScriptFullPath, 202)
        TrayItemSetState($enableTray,$TRAY_UNCHECKED)
        $enabled = False
	EndIf
EndFunc

Func _iniCheck($iniFile)
    If Not FileExists($iniFile) Or _
    IniRead($iniFile, 'Options', 'Main', '') == '' Or _
    IniRead($iniFile, 'Options', 'Emulate Mouse Move', '') == '' Or _
    IniRead($iniFile, 'Options', 'Move Mouse Every', '') == '' Then
        FileDelete($iniFile)
        IniWrite($iniFile, 'Options', 'Main', '^#1')
        IniWrite($iniFile, 'Options', 'Emulate Mouse Move', '1')
        IniWrite($iniFile, 'Options', 'Move Mouse Every', '30')
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
    $emuVal = IniRead($iniFile, 'Options', 'Move Mouse Every', '')
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    ;read main hotkey
    Local $appHotkey = IniRead($iniFile, 'Options', 'Main', '')
    Local $k = StringRight($appHotkey, 1)
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
EndFunc

Func _guiToIni($iniFile) ;reads gui and saves to ini and sets global hotkey only
    ;main hotkey
    Local $oldHotkey = IniRead($iniFile, 'Options', 'Main', '') ;get old hotkey
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($ctrlCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '^'
    If BitAND(GUICtrlRead($altCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '!'
    If BitAND(GUICtrlRead($shiftCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '+'
    If BitAND(GUICtrlRead($winCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '#'
    $appHotkey &= StringLower(GUICtrlRead($keyDown))
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
EndFunc

Func _decodeHotkey($hotkey)
    Local $decode = ''
    If StringInStr($hotkey,'^') Then $decode &= 'Ctrl + '
    If StringInStr($hotkey,'!') Then $decode &= 'Alt + '
    If StringInStr($hotkey,'+') Then $decode &= 'Shift + '
    If StringInStr($hotkey,'#') Then $decode &= 'Win + '
    $decode &= StringUpper(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'^',''),'!',''),'+',''),'#','')) ;get the last key
    Return($decode)
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
    ;~ ConsoleWrite($aRet[0]&@LF)
    Return $aRet[0] ;previous state (typically 0x80000000 [-2147483648])
EndFunc

Func _PowerResetState()
    ;flag: ES_CONTINUOUS (0x80000000) -> (default) -> used alone, it resets timers & allows regular sleep/power-savings mode
    Local $aRet=DllCall('kernel32.dll','long','SetThreadExecutionState','long',0x80000000)
    If @error Then Return SetError(2,@error,0x80000000)
    ;~ ConsoleWrite($aRet[0]&@LF)
    Return $aRet[0] ;previous state
EndFunc