#include-once
Global Const $STARTUP_KEY = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'

Func _StartupIsEnabled($key = $STARTUP_KEY, $name = $APP_NAME)
    RegRead($key, $name)
    Return @error = 0
EndFunc

Func _StartupSet($enabled, $key = $STARTUP_KEY, $name = $APP_NAME)
    If $enabled Then Return RegWrite($key, $name, 'REG_SZ', '"' & @ScriptFullPath & '"') = 1
    Local $result = RegDelete($key, $name)
    Return $result <> 2 And @error = 0
EndFunc
