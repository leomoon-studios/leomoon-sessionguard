@echo off
setlocal
if not defined AUTOIT_HOME (
    echo Set AUTOIT_HOME to your AutoIt installation directory first.
    exit /b 1
)
set "wrapper=%AUTOIT_HOME%\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3"
if not exist "%AUTOIT_HOME%\AutoIt3.exe" exit /b 1
if not exist "%wrapper%" (
    echo AutoIt3Wrapper was not found. Install SciTE4AutoIt3.
    exit /b 1
)
pushd "%~dp0"
if not exist "..\build" mkdir "..\build"
"%AUTOIT_HOME%\AutoIt3.exe" "%wrapper%" /in "LeoMoon SessionGuard.au3" /NoStatus
if errorlevel 1 (popd & exit /b 1)
popd
echo Built unsigned LeoMoon SessionGuard in build.
