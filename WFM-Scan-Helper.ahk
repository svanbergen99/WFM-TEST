#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - helper voor de teamkiezer -> WFM scan flow
;
; Werking:
; 1. Start dit script 1x.
; 2. Klik op WFM-TEST op "Rooster Log in".
; 3. WFM opent als popup; de teamkiezer wordt tegelijk op de achtergrond klaargezet.
; 4. De helper onthoudt het actieve WFM-venster.
; 5. Zodra de WFM-venstertitel na het inloggen verandert, wordt de teamkiezer
;    automatisch naar voren gehaald en always-on-top gezet.
; 6. Klik "KCD Team 3". De teamkiezer wordt zwart met "Rooster ophalen…".
; 7. De helper ziet het verzoek in de titel van de teamkiezer en start de actuele
;    6-weeks scanner in het reeds ingelogde WFM-venster.
; 8. WFM stuurt de data terug naar WFM-TEST en sluit; de teamkiezer sluit daarna ook.
;
; De helper leest alleen de scanner-code uit de publieke WFM-TEST repo.
; WFM-login/wachtwoorden worden niet gelezen of opgeslagen.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

TEAM_WAIT_MARKER := "WFM Team Selector"
TEAM_REQUEST_PREFIX := "WFM_SCAN_REQUEST_"
TEST_PAGE_TITLE := "Rooster WFM Test"

global ScannerUrls := SCANNER_URLS
global TeamWaitMarker := TEAM_WAIT_MARKER
global TeamRequestPrefix := TEAM_REQUEST_PREFIX
global TestPageTitle := TEST_PAGE_TITLE

global WfmHwnd := 0
global TeamHwnd := 0
global BaselineTitle := ""
global TitleCandidate := ""
global TitleCandidateTicks := 0
global ChangedCandidate := ""
global ChangedTicks := 0
global TeamPresented := false
global LastHandledRequest := ""
global ScanBusy := false
global HelperGui := 0
global StatusText := 0

BuildHelper()
SetTimer(MonitorWindows, 200)

BuildHelper() {
    global HelperGui, StatusText
    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper")
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10
    HelperGui.SetFont("s9 Bold", "Segoe UI")
    StatusText := HelperGui.AddText("w230 Center", "Wacht op Rooster Log in")
    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w230 h32", "Team kiezer tonen (fallback)")
    btn.OnEvent("Click", (*) => PresentTeamSelector(true))
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

MonitorWindows(*) {
    global WfmHwnd, TeamHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks
    global ChangedCandidate, ChangedTicks, TeamPresented, LastHandledRequest, ScanBusy
    global TeamWaitMarker, TeamRequestPrefix, TestPageTitle, StatusText

    ; Zoek de browser-popup van onze eigen teamkiezer.
    foundTeam := 0
    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try title := WinGetTitle("ahk_id " hwnd)
        catch continue
        if InStr(title, TeamWaitMarker) || InStr(title, TeamRequestPrefix) {
            foundTeam := hwnd
            break
        }
    }

    if foundTeam {
        if (!TeamHwnd || TeamHwnd != foundTeam) {
            TeamHwnd := foundTeam
            TeamPresented := false
            LastHandledRequest := ""
            try StatusText.Text := "Teamkiezer gevonden; wacht op WFM"
        }
    } else if TeamHwnd {
        ResetFlow()
        return
    }

    if !TeamHwnd
        return

    ; Als de gebruiker het team kiest verandert de titel naar WFM_SCAN_REQUEST_...
    try teamTitle := WinGetTitle("ahk_id " TeamHwnd)
    catch teamTitle := ""

    if InStr(teamTitle, TeamRequestPrefix) = 1 {
        if (!ScanBusy && teamTitle != LastHandledRequest) {
            LastHandledRequest := teamTitle
            ScanBusy := true
            SetTimer(StartScanFromTeamRequest, -10)
        }
        return
    }

    ; Het actieve Edge-venster dat niet onze testpagina/teamkiezer is, is in deze flow WFM.
    active := WinExist("A")
    if active && IsEdgeWindow(active) && active != TeamHwnd {
        try activeTitle := WinGetTitle("ahk_id " active)
        catch activeTitle := ""
        if !InStr(activeTitle, TeamWaitMarker) && !InStr(activeTitle, TeamRequestPrefix) && !InStr(activeTitle, TestPageTitle) {
            if (!WfmHwnd || WfmHwnd != active) {
                WfmHwnd := active
                BaselineTitle := ""
                TitleCandidate := ""
                TitleCandidateTicks := 0
                ChangedCandidate := ""
                ChangedTicks := 0
                TeamPresented := false
                try StatusText.Text := "WFM gevonden; wacht op login"
            }
        }
    }

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd))
        return

    try currentTitle := WinGetTitle("ahk_id " WfmHwnd)
    catch return

    ; Eerst laten we de titel van de loginpagina stabiel worden. Dat voorkomt dat een
    ; eerste laad-titel direct als "login voltooid" wordt gezien.
    if (BaselineTitle = "") {
        if (currentTitle = TitleCandidate) {
            TitleCandidateTicks += 1
        } else {
            TitleCandidate := currentTitle
            TitleCandidateTicks := 0
        }
        if (currentTitle != "" && TitleCandidateTicks >= 5) {
            BaselineTitle := currentTitle
            try StatusText.Text := "WFM login klaar voor detectie"
        }
        return
    }

    if TeamPresented
        return

    ; Na login navigeert WFM normaal naar de applicatie en verandert de venstertitel.
    ; We eisen dat de nieuwe titel ongeveer 1 seconde stabiel is.
    if (currentTitle != BaselineTitle && currentTitle != "") {
        if (currentTitle = ChangedCandidate) {
            ChangedTicks += 1
        } else {
            ChangedCandidate := currentTitle
            ChangedTicks := 0
        }
        if (ChangedTicks >= 5) {
            PresentTeamSelector(false)
        }
    } else {
        ChangedCandidate := ""
        ChangedTicks := 0
    }
}

PresentTeamSelector(force := false) {
    global TeamHwnd, WfmHwnd, TeamPresented, StatusText

    if (!TeamHwnd || !WinExist("ahk_id " TeamHwnd)) {
        if force
            MsgBox("De teamkiezer-popup is niet gevonden.`n`nKlik eerst op 'Rooster Log in' op WFM-TEST.", "WFM Bridge Helper")
        return
    }

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd)) {
        if force
            MsgBox("Het WFM-venster is nog niet gekoppeld.`n`nKlik eenmaal in het ingelogde WFM-venster en probeer opnieuw.", "WFM Bridge Helper")
        return
    }

    try WinSetAlwaysOnTop(1, "ahk_id " TeamHwnd)
    try WinActivate("ahk_id " TeamHwnd)
    TeamPresented := true
    try StatusText.Text := "Kies nu KCD Team 3"
}

StartScanFromTeamRequest(*) {
    global WfmHwnd, TeamHwnd, ScanBusy, StatusText

    target := WfmHwnd
    if (!target || !WinExist("ahk_id " target)) {
        ScanBusy := false
        MsgBox("Het WFM-venster is niet meer beschikbaar.", "WFM Bridge Helper")
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
        MsgBox("De opgehaalde scanner begint niet met javascript:.`nDe scan is voor de veiligheid niet gestart.", "WFM Bridge Helper")
        return
    }

    oldClipboard := ClipboardAll()

    try {
        ; De teamkiezer blijft always-on-top en dus zichtbaar als zwart laadscherm.
        ; WFM krijgt alleen tijdelijk de toetsenbordfocus achter dat venster.
        if (TeamHwnd && WinExist("ahk_id " TeamHwnd))
            WinSetAlwaysOnTop(1, "ahk_id " TeamHwnd)

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

        try StatusText.Text := "6-weeks scan gestart"

        ; Zet de teamkiezer nogmaals always-on-top. De scanner draait ondertussen in WFM.
        Sleep(120)
        if (TeamHwnd && WinExist("ahk_id " TeamHwnd))
            WinSetAlwaysOnTop(1, "ahk_id " TeamHwnd)
    }
    catch Error as err {
        MsgBox("De scanner kon niet in WFM worden gestart.`n`n" err.Message, "WFM Bridge Helper")
    }
    finally {
        A_Clipboard := oldClipboard
        ; Niet meteen opnieuw dezelfde titel verwerken.
        SetTimer(ReleaseScanBusy, -2500)
    }
}

ReleaseScanBusy(*) {
    global ScanBusy
    ScanBusy := false
}

IsEdgeWindow(hwnd) {
    try return StrLower(WinGetProcessName("ahk_id " hwnd)) = "msedge.exe"
    catch return false
}

ResetFlow() {
    global WfmHwnd, TeamHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks
    global ChangedCandidate, ChangedTicks, TeamPresented, LastHandledRequest, ScanBusy, StatusText
    WfmHwnd := 0
    TeamHwnd := 0
    BaselineTitle := ""
    TitleCandidate := ""
    TitleCandidateTicks := 0
    ChangedCandidate := ""
    ChangedTicks := 0
    TeamPresented := false
    LastHandledRequest := ""
    ScanBusy := false
    try StatusText.Text := "Wacht op Rooster Log in"
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
