# LeoMoon SessionGuard

Version 1.3.6 is a Windows tray utility for protecting a session from restart and optionally preventing sleep or emulating mouse activity. It requires Windows Vista or later.

The application ships as one executable, `LeoMoon SessionGuard.exe`. The executable runs a second, hidden instance of itself in watchdog mode while guarding is enabled. On first launch, it creates `LeoMoon SessionGuard.ini` beside the executable, so that directory must be writable.

The portable ZIP must be extracted to a writable folder. The per-user installer uses the current user's local application-data folder. Upgrades do not replace the INI; uninstall leaves it in place so settings can be recovered. The installer offers a checked-by-default startup option using the same current-user registry entry as the application's Settings; uninstall removes that entry.

## Local build

Install AutoIt and SciTE4AutoIt3, including AutoIt3Wrapper. In Command Prompt, set `AUTOIT_HOME` to the AutoIt installation directory and run:

```bat
set "AUTOIT_HOME=C:\path\to\AutoIt3"
src\_build.bat
```

The script builds an unsigned x86 executable with both tray icons in `build`. It does not require a signing certificate.

## Windows packages

After building with `scripts/build-windows.ps1`, run `scripts/package-windows.ps1` with the build output directory, version, commit, an Inno Setup compiler path, and an empty artifact directory. It creates a portable ZIP, per-user setup executable, release manifest, and SHA-256 checksums. Run `scripts/verify-windows-package.ps1` to verify those artifacts. The ZIP contains the executable; the INI is created when the app first runs.
