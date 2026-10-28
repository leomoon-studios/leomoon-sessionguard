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
#include "core/PowerState.au3"
#include "core/IdleGuard.au3"
#include "core/AppConstants.au3"
#include "app/StartupRegistration.au3"

; The helper must branch before either the main singleton or tray is created.
If $CmdLine[0] > 0 And $CmdLine[1] = '--watchdog' Then
    If $CmdLine[0] = 3 Then _WatchdogRun($CmdLine[2], $CmdLine[3])
    Exit
EndIf

OnAutoItExitRegister("_PowerCleanup")
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
Global $idleTimer = TimerInit(), $nMsg, $tMsg

While 1
    _TrayCheckWatchdog()
    If TimerDiff($idleTimer) >= 250 Then
        $idleTimer = TimerInit()
        If Not _IdleCheck($enabled, $emu, $emuVal) Then
            $emu = False
            _ExtMsgBox(48, 'OK', 'Mouse activity error', 'Mouse activity could not be simulated. It has been disabled until settings are reapplied.', 0)
        EndIf
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
    If Not _PowerSet($enabled And $noSleep) Then
        _ExtMsgBox(48, 'OK', 'Power state error', 'SessionGuard could not update the sleep-prevention request.', 0)
        Return False
    EndIf
    Return True
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
    Local $size = WinGetClientSize($win, '')
    Local $y = (@DesktopHeight / 2) - ($size[1] / 2)
    Local $x = (@DesktopWidth / 2) - ($size[0] / 2)
    Return WinMove($win, '', $x, $y)
EndFunc
