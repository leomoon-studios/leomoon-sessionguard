#include-once

Global $g_powerOwned = False, $g_powerPrevious = 0, $g_powerCall = '_PowerSystemCall'
Global Const $POWER_CONTINUOUS = 0x80000000, $POWER_KEEP_ALIVE = 0x80000003

Func _PowerSystemCall($flags)
    Local $result = DllCall('kernel32.dll', 'dword', 'SetThreadExecutionState', 'dword', $flags)
    If @error Then Return SetError(1, 0, 0)
    If $result[0] = 0 Then Return SetError(1, 0, 0)
    Return $result[0]
EndFunc

; Only restore a request that this process successfully acquired.
Func _PowerSet($wantActive)
    If $wantActive And Not $g_powerOwned Then
        Local $previous = Call($g_powerCall, $POWER_KEEP_ALIVE)
        If @error Or $previous = 0 Then Return False
        $g_powerPrevious = $previous
        $g_powerOwned = True
    ElseIf Not $wantActive And $g_powerOwned Then
        Local $restored = Call($g_powerCall, BitOR($POWER_CONTINUOUS, $g_powerPrevious))
        If @error Or $restored = 0 Then Return False
        $g_powerOwned = False
        $g_powerPrevious = 0
    EndIf
    Return True
EndFunc

Func _PowerCleanup()
    If Not _PowerSet(False) Then _ExtMsgBox(48, 'OK', 'Power state error', 'SessionGuard could not restore the previous sleep settings.', 0)
EndFunc
