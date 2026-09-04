$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=============================================='
Write-Host '  WFM Bridge - eenmalige installatie v12'
Write-Host '=============================================='
Write-Host ''
Write-Host 'De bestaande AutoHotkey WFM Bridge wordt voor jouw Windows-account geregistreerd.'
Write-Host 'Hiervoor zijn geen administratorrechten nodig.'
Write-Host ''

$installDir = Join-Path $env:LOCALAPPDATA 'WFMBridge'
$helperPath = Join-Path $installDir 'WFM-Scan-Helper.ahk'
$helperUrl = 'https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Scan-Helper.ahk'

[void](New-Item -ItemType Directory -Force -Path $installDir)
Invoke-WebRequest -UseBasicParsing -Uri ($helperUrl + '?v=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile $helperPath -Headers @{ 'Cache-Control' = 'no-cache' }

function Test-AutoHotkeyV2([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $version = (Get-Item -LiteralPath $Path).VersionInfo.ProductVersion
        return ($version -match '^2\.')
    } catch {
        return $false
    }
}

$candidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey.exe')
)

$ahkExe = $null
foreach ($candidate in $candidates) {
    if (Test-AutoHotkeyV2 $candidate) {
        $ahkExe = $candidate
        break
    }
}

if (-not $ahkExe) {
    foreach ($root in @((Join-Path $env:ProgramFiles 'AutoHotkey'), (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey'))) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $found = Get-ChildItem -LiteralPath $root -Filter 'AutoHotkey*.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { Test-AutoHotkeyV2 $_.FullName } |
            Select-Object -First 1
        if ($found) {
            $ahkExe = $found.FullName
            break
        }
    }
}

if (-not $ahkExe) {
    throw 'AutoHotkey v2 is niet gevonden op deze pc. Installeer eerst AutoHotkey v2 en voer daarna deze installer opnieuw uit.'
}

$protocolRoot = 'HKCU:\Software\Classes\wfmbridge'
[void](New-Item -Force -Path $protocolRoot)
Set-Item -Path $protocolRoot -Value 'URL:WFM Bridge Protocol'
[void](New-ItemProperty -Path $protocolRoot -Name 'URL Protocol' -Value '' -PropertyType String -Force)

$commandKey = $protocolRoot + '\shell\open\command'
[void](New-Item -Force -Path $commandKey)
$command = '"' + $ahkExe + '" "' + $helperPath + '" "%1"'
Set-Item -Path $commandKey -Value $command

Write-Host ''
Write-Host 'WFM Bridge is geinstalleerd.'
Write-Host ('AutoHotkey: ' + $ahkExe)
Write-Host ('Bridge:      ' + $helperPath)
Write-Host ''
Write-Host 'Er wordt nu een korte test gestart.'
Write-Host ''

Start-Process 'wfmbridge://ping'
