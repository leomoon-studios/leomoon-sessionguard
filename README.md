# LeoMoon SessionGuard

Version 1.3.6 is a Windows tray utility for protecting a session from restart and optionally preventing sleep or emulating mouse activity. It requires Windows Vista or later.

The application ships as one executable, `LeoMoon SessionGuard.exe`. The executable runs a second, hidden instance of itself in watchdog mode while guarding is enabled. On first launch, it creates `LeoMoon SessionGuard.ini` beside the executable, so that directory must be writable.

The portable ZIP must be extracted to a writable folder. The per-user installer uses the current user's local application-data folder. Upgrades do not replace the INI; uninstall leaves it in place so settings can be recovered. The installer offers a checked-by-default startup option using the same current-user registry entry as the application's Settings; uninstall removes that entry.

## Usage

Run SessionGuard, then use Ctrl + Win + Period to enable or disable guarding. You can change the shortcut from the tray menu's Settings window.

On supported Windows versions, SessionGuard uses GDI scaling to keep text and controls sharp on high-DPI displays. Restart the app after changing display scaling if its windows or tray icon do not update as expected.

## Local build

Install AutoIt and SciTE4AutoIt3, including AutoIt3Wrapper. In Command Prompt, set `AUTOIT_HOME` to the AutoIt installation directory and run:

```bat
set "AUTOIT_HOME=C:\path\to\AutoIt3"
src\_build.bat
```

The script builds an unsigned x86 executable with both tray icons in `build`. It does not require a signing certificate.

## Windows packages

After building with `scripts/build-windows.ps1`, run `scripts/package-windows.ps1` with the build output directory, version, commit, an Inno Setup compiler path, and an empty artifact directory. It creates a portable ZIP, per-user setup executable, release manifest, and SHA-256 checksums. Run `scripts/verify-windows-package.ps1` to verify those artifacts. The ZIP contains the executable; the INI is created when the app first runs.

## Signing and releases

Windows packages are unsigned when neither signing secret is configured. To enable signing, add both repository Actions secrets: `WINDOWS_CERTIFICATE_BASE64` (the base64-encoded PFX) and `WINDOWS_CERTIFICATE_PASSWORD` (its password). Configure neither for unsigned builds; configuring only one fails the build. The Windows build job signs and timestamps both the application and setup executable, verifies their signatures, and records the signed state in the manifest. A Windows SDK `signtool.exe` and access to the timestamp service are required for signed builds.

Use the **Build Windows packages** workflow's manual trigger and an `X.Y.Z` version to test a build without publishing a release. It builds unsigned or signed according to the configured secrets and uploads the packages as a workflow artifact. To publish a release after verification, create and push an exact version tag:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

The tag workflow runs checks before packaging and publishes only after the build succeeds. Do not commit certificates or passwords to the repository.
