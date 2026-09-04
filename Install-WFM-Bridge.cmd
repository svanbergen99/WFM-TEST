@echo off
setlocal
chcp 65001 >nul

echo.
echo ==============================================
echo   WFM Bridge - eenmalige installatie
echo ==============================================
echo.

echo De WFM Bridge wordt voor jouw Windows-account geinstalleerd.
echo Hiervoor zijn geen administratorrechten nodig.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$dir=Join-Path $env:LOCALAPPDATA 'WFMBridge';" ^
  "New-Item -ItemType Directory -Force -Path $dir ^| Out-Null;" ^
  "$script=Join-Path $dir 'WFM-Bridge.ps1';" ^
  "$url='https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Bridge.ps1';" ^
  "Invoke-WebRequest -UseBasicParsing -Uri ($url+'?v='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile $script -Headers @{'Cache-Control'='no-cache'};" ^
  "$root='HKCU:\Software\Classes\wfmbridge';" ^
  "New-Item -Force -Path $root ^| Out-Null;" ^
  "Set-Item -Path $root -Value 'URL:WFM Bridge Protocol';" ^
  "New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force ^| Out-Null;" ^
  "New-Item -Force -Path ($root+'\shell\open\command') ^| Out-Null;" ^
  "$exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe';" ^
  "$cmd='`"'+$exe+'`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"'+$script+'`" `"%%1`"';" ^
  "Set-Item -Path ($root+'\shell\open\command') -Value $cmd;" ^
  "Write-Host 'WFM Bridge is geinstalleerd.'"

if errorlevel 1 (
  echo.
  echo INSTALLATIE MISLUKT.
  echo Sluit dit venster en probeer opnieuw.
  echo.
  pause
  exit /b 1
)

echo.
echo Installatie klaar.
echo Er wordt nu een korte test gestart.
echo.
start "" "wfmbridge://ping"

echo Als je een melding ziet met "installatie geslaagd", is alles klaar.
echo Daarna hoef je dit installatiebestand niet meer te gebruiken.
echo.
pause
