#include "../src/app/WatchdogController.au3"
If $CmdLine[0] <> 2 Then Exit 2
If Not _WatchdogStart($CmdLine[1]) Then Exit 1
FileWrite($CmdLine[2], $g_watchdogPid)
; Exit without cleanup to exercise the watchdog's parent-death path.
Sleep(1500)
Exit
