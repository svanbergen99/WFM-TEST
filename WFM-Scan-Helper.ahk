#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - page button -> WFM scan helper
; v9: geen venstertitel-signaal meer vanaf de webpagina.
; De vaste Rooster ophalen-knop kopieert een korte marker naar het klembord.
; Deze helper ziet die marker, gebruikt een reeds gevonden Genesys WFM-venster
; en start daarin de bestaande 6-weeks scanner.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

REQUEST_MARKER := "WFM_SCAN_REQUEST_KCD_TEAM_3_V9"
HELPER_VERSION := "v9 clipboard"

global ScannerUrls := SCANNER_URLS
global RequestMarker := REQUEST_MARKER
global HelperVersion := HELPER_VERSION

global WfmHwnd := 0
global ScanBusy := false
global HelperGui := 0
global HelperStatus := 0

global LastWfmTitle := ""

BuildHelper()
SetTimer(MonitorBridge, 150)

BuildHelper() {
    global HelperGui, HelperStatus, HelperVersion

    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper " HelperVersion)
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10

    HelperGui.SetFont("s9 Bold", "Segoe UI")
    HelperStatus := HelperGui.AddText("w290 Center", "v9 helper actief - WFM zoeken...")

    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w290 h34", "SCAN WFM NU (test/fallback)")
    btn.OnEvent("Click", ManualScan)

    HelperGui.AddText("xm w290 Center c666666", "Laat dit venster tijdens de test open staan")
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

MonitorBridge(*) {
    global WfmHwnd, ScanBusy, RequestMarker, HelperStatus, LastWfmTitle

    candidate := FindWfmWindow()
    if candidate {
        WfmHwnd := candidate
        try title := WinGetTitle("ahk_id " candidate)
        catch title := "Genesys WFM"
        LastWfmTitle := title
        if !ScanBusy
            try HelperStatus.Text := "WFM GEVONDEN - klaar om te scannen"
    } else if !ScanBusy {
        WfmHwnd := 0
        LastWfmTitle := ""
        try HelperStatus.Text := "WFM NIET gevonden"
    }

    if ScanBusy
        return

    try clip := A_Clipboard
    catch clip := ""

    if (clip = RequestMarker) {
        ; Marker meteen wissen zodat dezelfde klik maar één keer wordt verwerkt.
        A_Clipboard := ""
        ScanBusy := true
        try HelperStatus.Text := "Scanverzoek ontvangen - WFM openen"
        SetTimer(StartScan, -20)
    }
}

ManualScan(*) {
    global ScanBusy, HelperStatus
    if ScanBusy
        return

    ScanBusy := true
    try HelperStatus.Text := "Handmatige testscan gestart"
    SetTimer(StartScan, -20)
}

FindWfmWindow() {
    ; Eerst streng zoeken op de titel die jouw echte ingelogde venster heeft.
    ; Voorbeeld: Genesys Workforce Management for Agents - My Schedule - Werk - Microsoft Edge
    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try title := WinGetTitle("ahk_id " hwnd)
        catch continue

        lower := StrLower(title)
        if (InStr(lower, "genesys workforce management")
            || InStr(lower, "workforce management for agents")
            || (InStr(lower, "my schedule") && InStr(lower, "workforce management"))) {
            return hwnd
        }
    }

    ; Fallback voor het compacte loginvenster / afwijkende WFM-titels.
    best := 0
    bestScore := -1

    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try title := WinGetTitle("ahk_id " hwnd)
        catch continue

        lower := StrLower(title)
        if InStr(lower, "rooster wfm test")
            continue

        try WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        catch continue

        if (w < 250 || h < 250)
            continue

        score := 0
        if InStr(lower, "genesys")
            score += 300
        if InStr(lower, "workforce")
            score += 250
        if InStr(lower, "wfm")
            score += 200
        if InStr(lower, "schedule")
            score += 150
        if InStr(lower, "login")
            score += 80
        if (w >= 320 && w <= 700 && h >= 380 && h <= 850)
            score += 60

        if (score > bestScore) {
            bestScore := score
            best := hwnd
        }
    }

    ; Geen willekeurig Edge-venster teruggeven: er moet echt WFM-bewijs zijn.
    return bestScore >= 200 ? best : 0
}

StartScan(*) {
    global WfmHwnd, ScanBusy, HelperStatus

    target := (WfmHwnd && WinExist("ahk_id " WfmHwnd)) ? WfmHwnd : FindWfmWindow()
    WfmHwnd := target

    if (!target || !WinExist("ahk_id " target)) {
        ScanBusy := false
        try HelperStatus.Text := "WFM NIET gevonden"
        MsgBox("Ik kan het Genesys WFM-venster niet vinden.`n`nLaat het ingelogde My Schedule-venster open staan en probeer opnieuw.", "WFM Bridge Helper v9")
        return
    }

    try code := DownloadScanner()
    catch Error as err {
        ScanBusy := false
        try HelperStatus.Text := "Scanner downloaden mislukt"
        MsgBox("De scanner-code kon niet worden geladen.`n`n" err.Message, "WFM Bridge Helper v9")
        return
    }

    if (SubStr(code, 1, 11) != "javascript:") {
        ScanBusy := false
        try HelperStatus.Text := "Ongeldige scanner-code"
        MsgBox("De opgehaalde scanner begint niet met javascript:.", "WFM Bridge Helper v9")
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
        Sleep(160)
        SendText("javascript:")
        Sleep(80)
        Send("^v")
        Sleep(180)
        Send("{Enter}")

        try HelperStatus.Text := "SCANNER GESTART in WFM"
        SetTimer(UnlockScan, -5000)
    }
    catch Error as err {
        ScanBusy := false
        try HelperStatus.Text := "Scan starten mislukt"
        MsgBox("De scanner kon niet in WFM worden gestart.`n`n" err.Message, "WFM Bridge Helper v9")
    }
    finally {
        A_Clipboard := oldClipboard
    }
}

UnlockScan(*) {
    global ScanBusy, HelperStatus
    ScanBusy := false
    if FindWfmWindow()
        try HelperStatus.Text := "WFM GEVONDEN - klaar om te scannen"
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
