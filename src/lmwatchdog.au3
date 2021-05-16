#NoTrayIcon

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_UseX64=n
;~ #AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Language=1033
;~ #AutoIt3Wrapper_Res_Icon_Add=resources\main.ico
#AutoIt3Wrapper_Res_Icon_Add=resources\disabled.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;#pragma compile(UPX, False)
;#pragma compile(x64, False)
#pragma compile(Out, ..\build\lmwatchdog.exe)
#pragma compile(Icon, resources\disabled.ico)
#pragma compile(Compression, 9)
#pragma compile(Comments, This program is freeware.)
#pragma compile(ProductName, LeoMoon Watchdog)
#pragma compile(FileDescription, LeoMoon Watchdog)
#pragma compile(FileVersion, 1.3.3.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.3.3.0)

#include <GUIConstantsEx.au3>
#include <WinAPISys.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <GUIConstants.au3>
#include <MsgBoxConstants.au3>
#include <resources\ExtMsgBox.au3>

Global $title = 'LeoMoon Watchdog'
Global $ver = '1.3.3'

_ExtMsgBoxSet(0, $SS_LEFT, -1, -1, 9, "Tahoma")

If _Singleton($title, 1) = 0 Then
	Exit
EndIf

If $CmdLine[0] == 0 Then
	_error()
	Exit
ElseIf $CmdLine[0] == 1 Then
    If $CmdLine[1] == '--mohafez' Then
		Global $g_hForm = GUICreate($title, 200, 200)
		GUIRegisterMsg($WM_QUERYENDSESSION, 'WM_QUERYENDSESSION')
		_WinAPI_SetProcessShutdownParameters(0x03FF)
		_WinAPI_ShutdownBlockReasonCreate($g_hForm, 'LeoMoon SessionGuard is protecting your session.')
		While 1
			Sleep(5000)
		WEnd
	Else
		_error()
	EndIf
Else
	_error()
EndIf

Func WM_QUERYENDSESSION($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam

	Switch $hWnd
		Case $g_hForm
			If _WinAPI_ShutdownBlockReasonQuery($g_hForm) Then
				Return 0
			EndIf
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc

Func _error()
    _ExtMsgBox(48, 'OK', 'Oops!', 'This is a helper program made to work with'&@LF&'LeoMoon SessionGuard.'&@LF&@LF&'Please run LeoMoon SessionGuard instead!'&@LF)
EndFunc