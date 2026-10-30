# Changelog

## 2.0.1 - 2026-10-29

- Improved high-DPI scaling for the tray menu, Settings window, and tray icons.

## 2.0.0 - 2026-10-27

- Combined SessionGuard and its watchdog into one executable with a separate hidden watchdog process.
- Added watchdog startup verification, failure reporting, and cleanup when guarding stops or the main process exits.
- Preserved valid settings when repairing an incomplete or malformed INI, and made settings saves recoverable.
- Added warnings for unavailable hotkeys while preserving the previous binding when a new shortcut cannot be registered.
- Improved sleep-prevention state handling and idle mouse emulation, including reporting failures and validating intervals.
- Added a portable Windows ZIP and a per-user installer with an optional desktop shortcut and a checked-by-default startup option.
- Preserved settings across upgrades and uninstall; the INI is created on first launch.
- Added reproducible unsigned x86 builds, strict checks, and regression tests for settings, hotkeys, power, mouse activity, and watchdog behavior.
- Added a GitHub Actions workflow for manual package builds and tag-triggered Windows releases.

## 1.3.6 - 2023-06-10

- Compiled with the latest compiler for better Windows 11 support.

## 1.3.5 - 2022-05-01

- Fixed an issue that toggled SessionGuard after saving settings.

## 1.3.4 - 2022-04-27

- Added a Prevent Sleeping checkbox under Settings.

## 1.3.3 - 2020-05-16

- Changed the default hotkey to Ctrl + Win + Period for new setups.
- Added the Numpad Dot key to hotkey selection.
- Bug fixes.

## 1.3.2

- Minor improvements.
- Digitally signed the application.

## 1.3.1

- Fixed the Settings window opening multiple times.

## 1.3.0

- Added options in Settings to change the hotkey, enable mouse movement emulation, and set its interval.
- Code optimizations and bug fixes.

## 1.2.0

- Added double-clicking the tray icon to toggle guarding.

## 1.1.0

- Minor changes.

## 1.0.0

- Initial release.
