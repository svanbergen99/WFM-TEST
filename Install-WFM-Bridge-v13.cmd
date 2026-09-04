@echo off
setlocal EnableExtensions
chcp 65001 >nul
title WFM Bridge Installer v13 - CMD only

echo.
echo ==============================================
echo   WFM Bridge - eenmalige installatie v13
echo ==============================================
echo.
echo Deze installer gebruikt GEEN PowerShell.
echo Dit is speciaal voor pc's met ConstrainedLanguage-beleid.
echo.

set "INSTALLDIR=%LOCALAPPDATA%\WFMBridge"
set "HELPER=%INSTALLDIR%\WFM-Scan-Helper.ahk"
set "REGFILE=%TEMP%\wfmbridge-v13-%RANDOM%%RANDOM%.reg"
set "HELPERURL=https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Scan-Helper.ahk?bridge=v13-%RANDOM%%RANDOM%"

if not exist "%INSTALLDIR%" mkdir "%INSTALLDIR%"
if errorlevel 1 goto :mkdir_error

echo [1/4] Bestaande WFM Bridge downloaden...
where curl.exe >nul 2>nul
if errorlevel 1 goto :curl_missing

curl.exe -fL --retry 2 --connect-timeout 15 -H "Cache-Control: no-cache" "%HELPERURL%" -o "%HELPER%"
if errorlevel 1 goto :download_error
if not exist "%HELPER%" goto :download_error

set "AHK="
if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey.exe"
if not defined AHK if exist "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey.exe" set "AHK=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey.exe"
if not defined AHK for /f "delims=" %%I in ('where AutoHotkey64.exe 2^>nul') do if not defined AHK set "AHK=%%I"
if not defined AHK for /f "delims=" %%I in ('where AutoHotkey.exe 2^>nul') do if not defined AHK set "AHK=%%I"

if not defined AHK goto :ahk_missing

echo [2/4] AutoHotkey v2 gevonden:
echo       %AHK%

echo [3/4] wfmbridge:// registreren voor jouw Windows-account...
set "AHKREG=%AHK:\=\\%"
set "HELPERREG=%HELPER:\=\\%"

> "%REGFILE%" echo Windows Registry Editor Version 5.00
>> "%REGFILE%" echo.
>> "%REGFILE%" echo [HKEY_CURRENT_USER\Software\Classes\wfmbridge]
>> "%REGFILE%" echo @="URL:WFM Bridge Protocol"
>> "%REGFILE%" echo "URL Protocol"=""
>> "%REGFILE%" echo.
>> "%REGFILE%" echo [HKEY_CURRENT_USER\Software\Classes\wfmbridge\shell\open\command]
>> "%REGFILE%" echo @="\"%AHKREG%\" \"%HELPERREG%\" \"%%1\""

reg.exe import "%REGFILE%" >nul
if errorlevel 1 goto :registry_error

del /q "%REGFILE%" >nul 2>nul

echo [4/4] Installatie controleren...
echo.
echo WFM Bridge is geregistreerd.
echo Er wordt nu wfmbridge://ping gestart.
echo.
start "" "wfmbridge://ping"

echo Als Windows of Edge vraagt om WFM Bridge te openen: kies Openen.
echo Daarna hoort een melding te verschijnen met: installatie geslaagd
echo.
echo INSTALLATIE V13 KLAAR.
echo.
pause
exit /b 0

:mkdir_error
echo.
echo INSTALLATIE MISLUKT: map kon niet worden gemaakt:
echo %INSTALLDIR%
goto :fail

:curl_missing
echo.
echo INSTALLATIE MISLUKT: curl.exe is niet beschikbaar op deze pc.
goto :fail

:download_error
echo.
echo INSTALLATIE MISLUKT: WFM-Scan-Helper.ahk kon niet worden gedownload.
goto :fail

:ahk_missing
echo.
echo INSTALLATIE MISLUKT: AutoHotkey v2 is niet gevonden.
echo De bridge zelf bestaat al, maar Windows heeft AutoHotkey v2 nodig om hem uit te voeren.
goto :fail

:registry_error
echo.
echo INSTALLATIE MISLUKT: wfmbridge:// kon niet in HKCU worden geregistreerd.
echo Dit gebruikt alleen jouw eigen Windows-account en vraagt geen administratorrechten.
goto :fail

:fail
if exist "%REGFILE%" del /q "%REGFILE%" >nul 2>nul
echo.
echo Stuur de volledige fouttekst uit dit venster door.
echo.
pause
exit /b 1
