@echo off
setlocal EnableExtensions
chcp 65001 >nul
title WFM Bridge Installer v14 - CMD only + portable AutoHotkey

echo.
echo ==============================================
echo   WFM Bridge - eenmalige installatie v14
echo ==============================================
echo.
echo Deze installer gebruikt GEEN PowerShell.
echo Als AutoHotkey v2 ontbreekt, wordt een portable versie automatisch toegevoegd.
echo.

set "INSTALLDIR=%LOCALAPPDATA%\WFMBridge"
set "HELPER=%INSTALLDIR%\WFM-Scan-Helper.ahk"
set "AHKDIR=%INSTALLDIR%\AutoHotkey"
set "REGFILE=%TEMP%\wfmbridge-v14-%RANDOM%%RANDOM%.reg"
set "AHKZIP=%TEMP%\AutoHotkey_2.0.27_%RANDOM%%RANDOM%.zip"
set "HELPERURL=https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Scan-Helper.ahk?bridge=v14-%RANDOM%%RANDOM%"
set "AHKURL=https://www.autohotkey.com/download/2.0/AutoHotkey_2.0.27.zip"

where curl.exe >nul 2>nul
if errorlevel 1 goto :curl_missing

if not exist "%INSTALLDIR%" mkdir "%INSTALLDIR%"
if errorlevel 1 goto :mkdir_error

echo [1/5] Bestaande WFM Bridge downloaden...
curl.exe -fL --retry 2 --connect-timeout 15 -H "Cache-Control: no-cache" "%HELPERURL%" -o "%HELPER%"
if errorlevel 1 goto :download_error
if not exist "%HELPER%" goto :download_error

set "AHK="n
if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey.exe"
if not defined AHK if exist "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey.exe" set "AHK=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey.exe"
if not defined AHK if exist "%AHKDIR%\AutoHotkey64.exe" set "AHK=%AHKDIR%\AutoHotkey64.exe"
if not defined AHK if exist "%AHKDIR%\AutoHotkey.exe" set "AHK=%AHKDIR%\AutoHotkey.exe"

if defined AHK goto :ahk_ready

echo [2/5] AutoHotkey v2 ontbreekt - portable AutoHotkey downloaden...
where tar.exe >nul 2>nul
if errorlevel 1 goto :tar_missing

if not exist "%AHKDIR%" mkdir "%AHKDIR%"
if errorlevel 1 goto :ahk_dir_error

curl.exe -fL --retry 2 --connect-timeout 20 "%AHKURL%" -o "%AHKZIP%"
if errorlevel 1 goto :ahk_download_error
if not exist "%AHKZIP%" goto :ahk_download_error

tar.exe -xf "%AHKZIP%" -C "%AHKDIR%"
if errorlevel 1 goto :ahk_extract_error

del /q "%AHKZIP%" >nul 2>nul

if exist "%AHKDIR%\AutoHotkey64.exe" set "AHK=%AHKDIR%\AutoHotkey64.exe"
if not defined AHK if exist "%AHKDIR%\AutoHotkey.exe" set "AHK=%AHKDIR%\AutoHotkey.exe"
if not defined AHK for /f "delims=" %%I in ('dir /b /s "%AHKDIR%\AutoHotkey64.exe" 2^>nul') do if not defined AHK set "AHK=%%I"
if not defined AHK for /f "delims=" %%I in ('dir /b /s "%AHKDIR%\AutoHotkey.exe" 2^>nul') do if not defined AHK set "AHK=%%I"
if not defined AHK goto :ahk_extract_error

:ahk_ready
echo [3/5] AutoHotkey v2 klaar:
echo       %AHK%

echo [4/5] wfmbridge:// registreren voor jouw Windows-account...
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

echo [5/5] Installatie controleren...
echo.
echo WFM Bridge is geregistreerd.
echo Er wordt nu wfmbridge://ping gestart.
echo.
start "" "wfmbridge://ping"

echo Als Windows of Edge vraagt om WFM Bridge te openen: kies Openen.
echo Daarna hoort een melding te verschijnen met: installatie geslaagd
echo.
echo INSTALLATIE V14 KLAAR.
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

:tar_missing
echo.
echo INSTALLATIE MISLUKT: tar.exe is niet beschikbaar op deze pc.
echo Daardoor kan de portable AutoHotkey ZIP niet worden uitgepakt.
goto :fail

:ahk_dir_error
echo.
echo INSTALLATIE MISLUKT: portable AutoHotkey-map kon niet worden gemaakt.
goto :fail

:ahk_download_error
echo.
echo INSTALLATIE MISLUKT: portable AutoHotkey v2 kon niet worden gedownload.
echo Bron: %AHKURL%
goto :fail

:ahk_extract_error
echo.
echo INSTALLATIE MISLUKT: portable AutoHotkey v2 kon niet worden uitgepakt of gevonden.
goto :fail

:registry_error
echo.
echo INSTALLATIE MISLUKT: wfmbridge:// kon niet in HKCU worden geregistreerd.
echo Dit gebruikt alleen jouw eigen Windows-account en vraagt geen administratorrechten.
goto :fail

:fail
if exist "%REGFILE%" del /q "%REGFILE%" >nul 2>nul
if exist "%AHKZIP%" del /q "%AHKZIP%" >nul 2>nul
echo.
echo Stuur de volledige fouttekst uit dit venster door.
echo.
pause
exit /b 1
