# LeoMoon SessionGuard

Version 1.3.6 is a Windows tray utility for protecting a session from restart and optionally preventing sleep or emulating mouse activity. It requires Windows Vista or later.

The application ships as one executable, `LeoMoon SessionGuard.exe`, and a bundled `LeoMoon SessionGuard.ini`. The executable runs a second, hidden instance of itself in watchdog mode while guarding is enabled. Settings are stored in the INI beside the executable, so that directory must be writable.

## Local build

Install AutoIt and SciTE4AutoIt3, including AutoIt3Wrapper. In Command Prompt, set `AUTOIT_HOME` to the AutoIt installation directory and run:

```bat
set "AUTOIT_HOME=C:\path\to\AutoIt3"
src\_build.bat
```

The script builds an unsigned x86 executable with both tray icons and copies the bundled INI to `build`. It does not require a signing certificate.
