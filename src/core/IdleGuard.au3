#include-once
#include <Timers.au3>

Global $g_idleRead = '_IdleSystemRead', $g_idleMove = '_IdleSystemMove'

Func _IdleSystemRead()
    Local $idle = _Timer_GetIdleTime()
    If @error Then Return SetError(1, 0, 0)
    Return $idle
EndFunc

Func _IdleSystemMove()
    Local $position = MouseGetPos()
    If @error Or Not IsArray($position) Then Return SetError(1, 0, False)
    Local $result = MouseMove($position[0], $position[1], 0)
    If @error Or Not $result Then Return SetError(1, 0, False)
    Return True
EndFunc

; Calls can be substituted by tests; no cursor movement occurs while disabled.
Func _IdleCheck($guardEnabled, $mouseEnabled, $interval)
    If Not $guardEnabled Or Not $mouseEnabled Then Return True
    If Not _SettingsValid($SETTING_INTERVAL, String($interval)) Then Return SetError(1, 0, False)
    Local $idle = Call($g_idleRead)
    If @error Or $idle < 0 Then Return SetError(2, 0, False)
    If $idle >= Number($interval) * 1000 Then
        Local $moved = Call($g_idleMove)
        If @error Or Not $moved Then Return SetError(3, 0, False)
    EndIf
    Return True
EndFunc
