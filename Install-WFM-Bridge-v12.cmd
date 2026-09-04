@echo off
setlocal
chcp 65001 >nul
title WFM Bridge Installer v12

echo.
echo ==============================================
echo   WFM Bridge - eenmalige installatie v12
echo ==============================================
echo.
echo DIT IS DE NIEUWE V12 INSTALLER.
echo Er staan geen oude ^-escape regels meer in dit bestand.
echo.
echo De installer wordt geladen...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/Install-WFM-Bridge-v12.ps1'; $p=Join-Path $env:TEMP 'Install-WFM-Bridge-v12.ps1'; Invoke-WebRequest -UseBasicParsing -Uri ($u+'?v='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile $p -Headers @{'Cache-Control'='no-cache'}; & $p"

if errorlevel 1 (
  echo.
  echo INSTALLATIE MISLUKT.
  echo Lees de foutmelding hierboven.
  echo.
  pause
  exit /b 1
)

echo.
echo Installatie-opdracht afgerond.
echo Als Windows of Edge vraagt om WFM Bridge te openen, kies Openen.
echo Bij een geslaagde test verschijnt: installatie geslaagd
echo.
pause
