#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - page button -> WFM scan helper
; v8: GEEN native team-popup meer.
; De vaste knop op WFM-TEST zet kort de Edge-venstertitel op een scan-signaal.
; Deze helper ziet dat signaal, zoekt het reeds geopende WFM-venster en start
; daarin de bestaande 6-weeks scanner.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

TEST_PAGE_TITLE := "Rooster WFM Test"
REQUEST_MARKER := "WFM_SCAN_REQUEST_KCD_TEAM_3"
HELPER_VERSION := "v8 page-knop"

global ScannerUrls := SCANNER_URLS
global TestPageTitle := TEST_PAGE_TITLE
global RequestMarker := REQUEST_MARKER
global HelperVersion := HELPER_VERSION

global WfmHwnd := 0
global ScanBusy := false
global LastRequestHwnd := 0

a_IconTip := "WFM Bridge Helper " HELPER_VERSION
SetTimer(MonitorScanRequest, 150)

MonitorScanRequest(*) {
    global ScanBusy, LastRequestHwnd, WfmHwnd

    requestHwnd := FindRequestWindow()

    if !requestHwnd {
        LastRequestHwnd := 0
        if (ScanBusy && WfmHwnd && !WinExist("ahk_id " WfmHwnd)) {
            ScanBusy := false
            WfmHwnd := 0
        }
        return
    }

    if ScanBusy
        return

    if (LastRequestHwnd = requestHwnd)
        return

    LastRequestHwnd := requestHwnd
    ScanBusy := true
    SetTimer(StartScanFromPage, -20)
}

FindRequestWindow() {
    global RequestMarker

    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try title := WinGetTitle("ahk_id " hwnd)
        catch continue

        if InStr(title, RequestMarker)
            return hwnd
    }

    return 0
}

FindWfmWindow(requestHwnd := 0) {
    global TestPageTitle, RequestMarker

    best := 0
    bestScore := -9999
    active := WinExist("A")

    for hwnd in WinGetList("ahk_exe msedge.exe") {
        if (requestHwnd && hwnd = requestHwnd)
            continue

        try title := WinGetTitle("ahk_id " hwnd)
        catch continue

        if InStr(title, TestPageTitle) || InStr(title, RequestMarker)
            continue

        try WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        catch continue

        if (w < 250 || h < 250)
            continue

        score := 0
        lower := StrLower(title)

        if InStr(lower, "wfm")
            score += 180
        if InStr(lower, "genesys")
            score += 180
        if InStr(lower, "workforce")
            score += 150
        if InStr(lower, "schedule")
            score += 80
        if InStr(lower, "login")
            score += 60

        ; De WFM-popup is tijdens login expres compact.
        if (w >= 320 && w <= 650 && h >= 380 && h <= 750)
            score += 170

        if (hwnd = active)
            score += 15

        if (score > bestScore) {
            bestScore := score
            best := hwnd
        }
    }

    return best
}

StartScanFromPage(*) {
    global WfmHwnd, ScanBusy, LastRequestHwnd

    requestHwnd := LastRequestHwnd
    target := FindWfmWindow(requestHwnd)
    WfmHwnd := target

    if (!target || !WinExist("ahk_id " target)) {
        ScanBusy := false
        MsgBox("Ik kan het WFM-venster niet vinden.`n`nOpen WFM via 'Rooster Log in', log volledig in en klik daarna opnieuw op 'Rooster ophalen'.", "WFM Bridge Helper")
        return
    }

    try code := DownloadScanner()
    catch Error as err {
        ScanBusy := false
        MsgBox("De scanner-code kon niet worden geladen.`n`n" err.Message, "WFM Bridge Helper")
        return
    }

    if (SubStr(code, 1, 11) != "javascript:") {
        ScanBusy := false
        MsgBox("De opgehaalde scanner begint niet met javascript:.", "WFM Bridge Helper")
        return
    }

    oldClipboard := ClipboardAll()

    try {
        PrepareWfmForScan(target)

        A_Clipboard := SubStr(code, 12)
        if !ClipWait(2)
            throw Error("De scanner kon niet tijdelijk naar het klembord worden gezet.")

        WinActivate("ahk_id " target)
        if !WinWaitActive("ahk_id " target, , 3)
            throw Error("Het WFM-venster kon niet actief worden gemaakt.")

        Send("^l")
        Sleep(140)
        SendText("javascript:")
        Sleep(70)
        Send("^v")
        Sleep(160)
        Send("{Enter}")
    }
    catch Error as err {
        ScanBusy := false
        MsgBox("De scanner kon niet in WFM worden gestart.`n`n" err.Message, "WFM Bridge Helper")
    }
    finally {
        A_Clipboard := oldClipboard
    }
}

PrepareWfmForScan(target) {
    ; Voor de scan vergroten we WFM naar de bekende desktop-layout.
    try {
        primary := MonitorGetPrimary()
        MonitorGetWorkArea(primary, &ml, &mt, &mr, &mb)
        availW := mr - ml
        availH := mb - mt
        w := Min(1100, Max(760, availW - 60))
        h := Min(820, Max(620, availH - 60))
        x := ml + Floor((availW - w) / 2)
        y := mt + Floor((availH - h) / 2)
        WinMove(x, y, w, h, "ahk_id " target)
        Sleep(300)
    }
}

DownloadScanner() {
    global ScannerUrls
    lastError := ""

    for _, url in ScannerUrls {
        try {
            request := ComObject("WinHttp.WinHttpRequest.5.1")
            request.Open("GET", url "?v=" A_TickCount, false)
            request.SetRequestHeader("Cache-Control", "no-cache")
            request.Send()

            if (request.Status = 200) {
                code := Trim(request.ResponseText, " `t`r`n")
                if (SubStr(code, 1, 11) = "javascript:")
                    return code
                lastError := "Onverwachte inhoud ontvangen van " url
            } else {
                lastError := "HTTP " request.Status " bij " url
            }
        }
        catch Error as err {
            lastError := err.Message
        }
    }

    throw Error(lastError != "" ? lastError : "Geen scanner-bron bereikbaar.")
}
