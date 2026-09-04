#Requires AutoHotkey v2.0
#SingleInstance Off
Persistent

; WFM Bridge v11
; Dezelfde bestaande AHK-bridge/scanner, maar nu ook rechtstreeks startbaar via:
;   wfmbridge://ping
;   wfmbridge://scan?team=KCD%20Team%203
;
; De website hoeft de helper daardoor niet vooraf open te hebben.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

HELPER_VERSION := "v11 protocol"

global ScannerUrls := SCANNER_URLS
global HelperVersion := HELPER_VERSION
global ScanBusy := false
global HelperGui := 0
global HelperStatus := 0

; Als Windows ons via het geregistreerde wfmbridge:// protocol start,
; verwerken we de opdracht meteen en sluiten we daarna weer af.
if (A_Args.Length >= 1) {
    uri := StrLower(A_Args[1])

    if InStr(uri, "wfmbridge://ping") {
        MsgBox("installatie geslaagd", "WFM Bridge")
        ExitApp()
    }

    if InStr(uri, "wfmbridge://scan") {
        SetTimer(() => StartScan(true), -180)
        return
    }
}

; Alleen wanneer het .ahk-bestand handmatig wordt gestart tonen we nog een
; klein diagnosevenster. Dit is niet nodig voor normaal gebruik via de pagina.
BuildHelper()
SetTimer(MonitorWfm, 300)

BuildHelper() {
    global HelperGui, HelperStatus, HelperVersion

    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper " HelperVersion)
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10
    HelperGui.SetFont("s9 Bold", "Segoe UI")
    HelperStatus := HelperGui.AddText("w300 Center", "WFM zoeken...")
    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w300 h36", "SCAN WFM NU (test/fallback)")
    btn.OnEvent("Click", (*) => StartScan(false))
    HelperGui.AddText("xm w300 Center c666666", "Normaal start Rooster ophalen deze bridge automatisch")
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

MonitorWfm(*) {
    global HelperStatus, ScanBusy
    if ScanBusy
        return
    try HelperStatus.Text := FindWfmWindow() ? "WFM GEVONDEN - klaar om te scannen" : "WFM NIET gevonden"
}

FindWfmWindow() {
    ; Eerst streng zoeken op de titel van het echte ingelogde WFM-venster.
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

    ; Fallback voor compacte login-/afwijkende WFM-vensters.
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

    return bestScore >= 200 ? best : 0
}

StartScan(exitAfter := false) {
    global ScanBusy, HelperStatus

    if ScanBusy
        return
    ScanBusy := true

    target := FindWfmWindow()

    if (!target || !WinExist("ahk_id " target)) {
        ScanBusy := false
        if !exitAfter
            try HelperStatus.Text := "WFM NIET gevonden"
        MsgBox("Ik kan het Genesys WFM-venster niet vinden.`n`nLaat het ingelogde My Schedule-venster open staan en probeer opnieuw.", "WFM Bridge")
        if exitAfter
            ExitApp()
        return
    }

    try code := DownloadScanner()
    catch Error as err {
        ScanBusy := false
        MsgBox("De scanner-code kon niet worden geladen.`n`n" err.Message, "WFM Bridge")
        if exitAfter
            ExitApp()
        return
    }

    if (SubStr(code, 1, 11) != "javascript:") {
        ScanBusy := false
        MsgBox("De opgehaalde scanner begint niet met javascript:.", "WFM Bridge")
        if exitAfter
            ExitApp()
        return
    }

    oldClipboard := ClipboardAll()

    try {
        if !exitAfter
            try HelperStatus.Text := "WFM gevonden - scanner starten"

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

        if !exitAfter {
            try HelperStatus.Text := "SCANNER GESTART in WFM"
            SetTimer(UnlockManualScan, -4500)
        }
    }
    catch Error as err {
        ScanBusy := false
        MsgBox("De scanner kon niet in WFM worden gestart.`n`n" err.Message, "WFM Bridge")
        if exitAfter
            ExitApp()
        return
    }
    finally {
        A_Clipboard := oldClipboard
    }

    ; Na injectie draait de scanner zelfstandig in WFM. De protocol-helper
    ; hoeft dus niet open te blijven.
    if exitAfter
        SetTimer(() => ExitApp(), -1200)
}

UnlockManualScan(*) {
    global ScanBusy, HelperStatus
    ScanBusy := false
    try HelperStatus.Text := FindWfmWindow() ? "WFM GEVONDEN - klaar om te scannen" : "WFM NIET gevonden"
}

PrepareWfmForScan(target) {
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
