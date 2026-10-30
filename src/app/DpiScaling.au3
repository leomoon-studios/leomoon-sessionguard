#include-once

Func _EnableGdiScaling()
    ; Keep DPI-unaware coordinates while Windows scales GDI text and controls.
    Local $result = DllCall('user32.dll', 'bool', 'SetProcessDpiAwarenessContext', 'ptr', -5)
    If Not @error And IsArray($result) And $result[0] Then Return True
    ; Preserve compatibility if a process context was already established.
    $result = DllCall('user32.dll', 'handle', 'SetThreadDpiAwarenessContext', 'ptr', -5)
    If @error Or Not IsArray($result) Or Not $result[0] Then Return False
    Return True
EndFunc
