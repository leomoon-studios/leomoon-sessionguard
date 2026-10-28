#include <WinAPISys.au3>
#include "../src/app/WatchdogController.au3"

Global $failures = 0
Func _assert($condition, $message)
    If Not $condition Then
        ConsoleWrite('FAIL: ' & $message & @CRLF)
        $failures += 1
    EndIf
EndFunc

If $CmdLine[0] <> 2 Then Exit 2
Local $exe = $CmdLine[1]
_assert(Not _WatchdogStart(@TempDir & '\no-such-sessionguard.exe'), 'missing executable fails')
_assert(Not _WatchdogRunning(), 'failed start leaves no owned process')
For $i = 1 To 3
    Local $started = _WatchdogStart($exe)
    _assert($started, 'watchdog handshake ' & $i)
    If $started Then
        _assert(_WatchdogRunning(), 'watchdog running ' & $i)
        Local $title = 'LeoMoon Watchdog ' & @AutoItPID
        Local $window = DllCall('user32.dll', 'hwnd', 'FindWindowW', 'ptr', 0, 'wstr', $title)
        _assert(Not @error And $window[0] <> 0, 'hidden watchdog window')
        If IsArray($window) And $window[0] Then
            _assert(_WinAPI_ShutdownBlockReasonQuery($window[0]) <> '', 'shutdown reason')
            Local $message = DllCall('user32.dll', 'lresult', 'SendMessageTimeoutW', 'hwnd', $window[0], 'uint', 0x11, _
                'wparam', 0, 'lparam', 0, 'uint', 2, 'uint', 3000, 'dword_ptr*', 1)
            _assert(Not @error And $message[0] <> 0 And $message[7] = 0, 'controlled shutdown query is denied')
        EndIf
        Local $pid = $g_watchdogPid
        _WatchdogStop()
        _assert(Not ProcessExists($pid), 'watchdog stopped ' & $i)
    EndIf
Next

If _WatchdogStart($CmdLine[2], @AutoItExe) Then
    _assert(_WatchdogRunning(), 'source-mode watchdog running')
    _assert(_WatchdogStop(), 'source-mode watchdog stops')
Else
    _assert(False, 'source-mode watchdog starts')
EndIf

If _WatchdogStart($exe) Then
    DllCall('kernel32.dll', 'bool', 'TerminateProcess', 'handle', $g_watchdogProcess, 'uint', 1)
    _WatchdogWait($g_watchdogProcess, 3000)
    _assert(Not _WatchdogRunning(), 'unexpected exit detected')
    _WatchdogStop()
Else
    _assert(False, 'start before unexpected exit')
EndIf

Local $resultFile = @TempDir & '\SessionGuard-owner-' & @AutoItPID & '.txt'
Local $owner = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptDir & '\WatchdogOwner.au3" "' & $exe & '" "' & $resultFile & '"', @ScriptDir, @SW_HIDE)
Local $timer = TimerInit()
While Not FileExists($resultFile) And ProcessExists($owner) And TimerDiff($timer) < 10000
    Sleep(50)
WEnd
If FileExists($resultFile) Then
    Local $childPid = Number(FileRead($resultFile))
    Local $child = DllCall('kernel32.dll', 'handle', 'OpenProcess', 'dword', 0x00100001, 'bool', False, 'dword', $childPid)
    _assert(Not @error And $child[0] <> 0, 'open owned child')
    ProcessWaitClose($owner, 5)
    If IsArray($child) And $child[0] Then
        _assert(_WatchdogWait($child[0], 5000) = 0, 'watchdog exits after parent exits')
        If _WatchdogWait($child[0], 0) = 0x102 Then DllCall('kernel32.dll', 'bool', 'TerminateProcess', 'handle', $child[0], 'uint', 1)
        _WatchdogCloseHandle($child[0])
    EndIf
Else
    _assert(False, 'owner started watchdog')
    If ProcessExists($owner) Then ProcessClose($owner)
EndIf
FileDelete($resultFile)
ConsoleWrite('Watchdog failures: ' & $failures & @CRLF)
Exit $failures
