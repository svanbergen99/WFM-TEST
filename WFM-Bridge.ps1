param(
    [Parameter(Position=0)]
    [string]$RequestUri = "wfmbridge://scan?team=KCD%20Team%203"
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

if (-not ('WfmBridge.Win32' -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
namespace WfmBridge {
  public static class Win32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int width, int height, bool repaint);
  }
}
"@
}

function Show-BridgeMessage([string]$text, [string]$title = 'WFM Bridge') {
    [System.Windows.Forms.MessageBox]::Show($text, $title, 'OK', 'Information') | Out-Null
}

function Get-EdgeWindows {
    $items = New-Object System.Collections.Generic.List[object]
    $callback = [WfmBridge.Win32+EnumWindowsProc]{
        param([IntPtr]$hWnd, [IntPtr]$lParam)
        if (-not [WfmBridge.Win32]::IsWindowVisible($hWnd)) { return $true }
        $len = [WfmBridge.Win32]::GetWindowTextLength($hWnd)
        if ($len -le 0) { return $true }
        $sb = New-Object System.Text.StringBuilder ($len + 1)
        [void][WfmBridge.Win32]::GetWindowText($hWnd, $sb, $sb.Capacity)
        $title = $sb.ToString()
        [uint32]$pid = 0
        [void][WfmBridge.Win32]::GetWindowThreadProcessId($hWnd, [ref]$pid)
        try { $p = Get-Process -Id $pid -ErrorAction Stop } catch { return $true }
        if ($p.ProcessName -ne 'msedge') { return $true }
        $items.Add([pscustomobject]@{ Hwnd=$hWnd; Pid=[int]$pid; Title=$title })
        return $true
    }
    [void][WfmBridge.Win32]::EnumWindows($callback, [IntPtr]::Zero)
    return $items
}

function Find-WfmWindow {
    $best = $null
    $bestScore = -100000
    foreach ($w in (Get-EdgeWindows)) {
        $title = $w.Title
        if ($title -match 'Rooster WFM Test') { continue }
        $score = 0
        if ($title -match 'Genesys Workforce Management') { $score += 1000 }
        if ($title -match 'Workforce Management') { $score += 500 }
        if ($title -match 'My Schedule') { $score += 300 }
        if ($title -match 'Genesys') { $score += 250 }
        if ($title -match 'Login') { $score += 100 }
        if ($score -gt $bestScore) { $bestScore = $score; $best = $w }
    }
    if ($bestScore -lt 500) { return $null }
    return $best
}

function Get-ScannerCode {
    $urls = @(
        'https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt',
        'https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt'
    )
    $last = $null
    foreach ($url in $urls) {
        try {
            $u = $url + '?v=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $code = (Invoke-WebRequest -UseBasicParsing -Uri $u -Headers @{ 'Cache-Control'='no-cache' } -TimeoutSec 12).Content.Trim()
            if ($code.StartsWith('javascript:')) { return $code }
            $last = 'Scannerinhoud begint niet met javascript:'
        } catch { $last = $_.Exception.Message }
    }
    throw "Scanner kon niet worden geladen. $last"
}

function Prepare-WfmWindow($w) {
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $width = [Math]::Min(1100, [Math]::Max(760, $area.Width - 60))
    $height = [Math]::Min(820, [Math]::Max(620, $area.Height - 60))
    $x = $area.Left + [Math]::Floor(($area.Width - $width) / 2)
    $y = $area.Top + [Math]::Floor(($area.Height - $height) / 2)
    [void][WfmBridge.Win32]::ShowWindow($w.Hwnd, 9)
    [void][WfmBridge.Win32]::MoveWindow($w.Hwnd, $x, $y, $width, $height, $true)
    Start-Sleep -Milliseconds 250
}

function Activate-WfmWindow($w) {
    [void][WfmBridge.Win32]::ShowWindow($w.Hwnd, 9)
    [void][WfmBridge.Win32]::SetForegroundWindow($w.Hwnd)
    try { [void][Microsoft.VisualBasic.Interaction]::AppActivate($w.Pid) } catch {}
    Start-Sleep -Milliseconds 250
}

try {
    $uri = [Uri]$RequestUri
    $action = $uri.Host.ToLowerInvariant()

    if ($action -eq 'ping') {
        Show-BridgeMessage 'WFM Bridge is correct geinstalleerd. Je kunt dit venster sluiten en daarna WFM-TEST gebruiken.' 'WFM Bridge - installatie geslaagd'
        exit 0
    }

    if ($action -ne 'scan') { throw "Onbekende WFM Bridge-opdracht: $action" }

    $wfm = Find-WfmWindow
    if (-not $wfm) {
        throw 'Ik kan geen geopend Genesys Workforce Management-venster vinden. Open WFM via Rooster Log in, log volledig in en probeer opnieuw.'
    }

    $code = Get-ScannerCode
    $payload = $code.Substring(11)

    Prepare-WfmWindow $wfm
    Set-Clipboard -Value $payload
    Activate-WfmWindow $wfm

    [System.Windows.Forms.SendKeys]::SendWait('^l')
    Start-Sleep -Milliseconds 140
    [System.Windows.Forms.SendKeys]::SendWait('javascript:')
    Start-Sleep -Milliseconds 70
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 160
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
}
catch {
    Show-BridgeMessage $_.Exception.Message 'WFM Bridge - scan kon niet starten'
    exit 1
}
