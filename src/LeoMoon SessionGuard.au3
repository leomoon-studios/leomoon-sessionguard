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
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)

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
#include "app/WatchdogController.au3"
#include "watchdog/Watchdog.au3"
#include "core/HotkeyCodec.au3"
#include "core/Settings.au3"
#include "core/AppConstants.au3"
#include "app/StartupRegistration.au3"

; The helper must branch before either the main singleton or tray is created.
If $CmdLine[0] > 0 And $CmdLine[1] = '--watchdog' Then
    If $CmdLine[0] = 3 Then _WatchdogRun($CmdLine[2], $CmdLine[3])
    Exit
EndIf

OnAutoItExitRegister("_PowerResetState")
OnAutoItExitRegister("_WatchdogStop")

;global vars
Global $title = $APP_NAME
Global $ver = $APP_VERSION
Global $noSleep = True
Global $emu = True
Global $emuVal = 30
Global $ini = @ScriptDir&'\'&$title&'.ini'
Global $activeHotkey = ''
;global gui vars
Global $power
#include "app/TrayController.au3"
#include "gui/SettingsWindow.au3"

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

_TrayCreate()
_readHotkey($ini)
_iniToApply($ini)
_TrayShow()
_guard()

While 1
    _TrayCheckWatchdog()
    If $enabled And $emu And StringIsDigit($emuVal) And _Timer_GetIdleTime()/1000 > $emuVal Then
        Local $aPos = MouseGetPos()
        MouseMove($aPos[0],$aPos[1],0)
        ;~ ConsoleWrite('moving mouse to '&$aPos[0]&', '&$aPos[1]&', wait: '&$emuVal&@LF)
    EndIf
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE, $cancelBtn ;, $escDummy
            _SettingsWindowClose()
        Case $emuCbox
            _SettingsWindowUpdateMouse()
        Case $saveBtn
            If Not _guiToIni($ini) Then ContinueLoop
            _iniToApply($ini)
            _noSleep()
            If Not _StartupSet(BitAND(GUICtrlRead($startupCbox), $GUI_CHECKED) = 1) Then
                _ExtMsgBox(48, 'OK', 'Startup error', 'Settings were saved, but the Windows startup option could not be changed.', 0)
                ContinueLoop
            EndIf
            _SettingsWindowClose()
    EndSwitch
    $tMsg = TrayGetMsg()
    If _TrayHandleEvent($tMsg) Then Exit
WEnd

Exit

;##########################################################
;########## FUNCTIONS #####################################
;##########################################################


Func _noSleep()
    if $enabled And $noSleep Then
        $power = _PowerKeepAlive()
    Else
        _PowerResetState()
    EndIf
    ;~ ConsoleWrite($noSleep&@LF)
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
