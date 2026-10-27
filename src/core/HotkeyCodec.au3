#include-once
#include <String.au3>

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
