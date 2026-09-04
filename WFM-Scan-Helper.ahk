#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - native zelfstandige teamkiezer + WFM scan helper
;
; Belangrijk verschil met de vorige test:
; - De teamkiezer is GEEN website/Edge-popup meer.
; - De teamkiezer is een los Windows/AutoHotkey-venster.
; - Alleen WFM wordt nog door de testpagina in Edge geopend.
; - Na login toont deze helper de native teamkiezer boven WFM.
; - KCD Team 3 kiezen start direct de bestaande 6-weeks scanner.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

TEST_PAGE_TITLE := "Rooster WFM Test"

global ScannerUrls := SCANNER_URLS
global TestPageTitle := TEST_PAGE_TITLE

global WfmHwnd := 0
global BaselineTitle := ""
global TitleCandidate := ""
global TitleCandidateTicks := 0
global ChangedCandidate := ""
global ChangedTicks := 0
global TeamPresented := false
global ScanBusy := false

global HelperGui := 0
global HelperStatus := 0
global TeamGui := 0
global TeamTitle := 0
global TeamHint := 0
global TeamDropdown := 0

BuildHelper()
SetTimer(MonitorWfm, 200)

BuildHelper() {
    global HelperGui, HelperStatus
    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper")
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10
    HelperGui.SetFont("s9 Bold", "Segoe UI")
    HelperStatus := HelperGui.AddText("w230 Center", "Wacht op Rooster Log in")
    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w230 h32", "Team kiezer tonen (fallback)")
    btn.OnEvent("Click", (*) => ShowNativeTeamSelector(true))
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

MonitorWfm(*) {
    global WfmHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks
    global ChangedCandidate, ChangedTicks, TeamPresented, TestPageTitle, HelperStatus

    if (WfmHwnd && !WinExist("ahk_id " WfmHwnd)) {
        ResetFlow()
        return
    }

    active := WinExist("A")
    if active && IsEdgeWindow(active) {
        try activeTitle := WinGetTitle("ahk_id " active)
        catch activeTitle := ""

        if !InStr(activeTitle, TestPageTitle) {
            if (!WfmHwnd || WfmHwnd != active) {
                WfmHwnd := active
                BaselineTitle := ""
                TitleCandidate := ""
                TitleCandidateTicks := 0
                ChangedCandidate := ""
                ChangedTicks := 0
                TeamPresented := false
                try HelperStatus.Text := "WFM gevonden; wacht op login"
            }
        }
    }

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd))
        return

    if TeamPresented {
        KeepTeamOnTop()
        return
    }

    try currentTitle := WinGetTitle("ahk_id " WfmHwnd)
    catch return

    ; Eerst de login-titel ongeveer 1 seconde stabiel laten worden.
    if (BaselineTitle = "") {
        if (currentTitle = TitleCandidate) {
            TitleCandidateTicks += 1
        } else {
            TitleCandidate := currentTitle
            TitleCandidateTicks := 0
        }
        if (currentTitle != "" && TitleCandidateTicks >= 5) {
            BaselineTitle := currentTitle
            try HelperStatus.Text := "WFM login klaar voor detectie"
        }
        return
    }

    ; Na login verandert de WFM-titel normaal. Zodra die nieuwe titel stabiel is,
    ; tonen we onze volledig losse native teamkiezer.
    if (currentTitle != BaselineTitle && currentTitle != "") {
        if (currentTitle = ChangedCandidate) {
            ChangedTicks += 1
        } else {
            ChangedCandidate := currentTitle
            ChangedTicks := 0
        }
        if (ChangedTicks >= 5)
            ShowNativeTeamSelector(false)
    } else {
        ChangedCandidate := ""
        ChangedTicks := 0
    }
}

ShowNativeTeamSelector(force := false) {
    global WfmHwnd, TeamPresented, TeamGui, TeamTitle, TeamHint, TeamDropdown, HelperStatus

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd)) {
        if force
            MsgBox("Het WFM-venster is nog niet gekoppeld.`n`nOpen WFM via 'Rooster Log in', log in en probeer opnieuw.", "WFM Bridge Helper")
        return
    }

    if IsObject(TeamGui) {
        try TeamGui.Destroy()
    }

    TeamGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "Rooster Teamkeuze")
    TeamGui.BackColor := "111827"
    TeamGui.MarginX := 40
    TeamGui.MarginY := 34

    TeamGui.SetFont("s20 Bold cFFFFFF", "Segoe UI")
    TeamTitle := TeamGui.AddText("w340 Center BackgroundTrans", "Selecteer je team")

    TeamGui.SetFont("s10 Norm cCBD5E1", "Segoe UI")
    TeamHint := TeamGui.AddText("xm y+12 w340 Center BackgroundTrans", "Kies het team waarvan je rooster moet worden opgehaald.")

    TeamGui.SetFont("s12 Norm c111827", "Segoe UI")
    TeamDropdown := TeamGui.AddDropDownList("xm y+24 w340 Choose1", ["Kies team", "KCD Team 3"])
    TeamDropdown.OnEvent("Change", TeamChanged)

    TeamGui.OnEvent("Escape", (*) => CancelTeamSelector())

    try WinSetAlwaysOnTop(0, "ahk_id " WfmHwnd)
    try WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " WfmHwnd)
    catch {
        wx := 0, wy := 0, ww := A_ScreenWidth, wh := A_ScreenHeight
    }

    w := 420
    h := 245
    x := wx + Floor((ww - w) / 2)
    y := wy + Floor((wh - h) / 2)
    TeamGui.Show("x" x " y" y " w" w " h" h)

    TeamPresented := true
    KeepTeamOnTop()
    SetTimer(KeepTeamOnTop, 150)
    try WinActivate("ahk_id " TeamGui.Hwnd)
    try HelperStatus.Text := "Kies nu KCD Team 3"
}

TeamChanged(ctrl, *) {
    global ScanBusy
    if (ctrl.Text != "KCD Team 3" || ScanBusy)
        return

    ScanBusy := true
    ShowLoadingState()
    SetTimer(StartScan, -80)
}

ShowLoadingState() {
    global TeamGui, TeamTitle, TeamHint, TeamDropdown, HelperStatus
    if !IsObject(TeamGui)
        return

    try TeamDropdown.Visible := false
    try TeamTitle.Text := "Rooster ophalen…"
    try TeamHint.Text := "Even geduld. WFM wordt automatisch gescand."
    try HelperStatus.Text := "6-weeks scan voorbereiden"
    KeepTeamOnTop()
}

KeepTeamOnTop(*) {
    global TeamPresented, TeamGui, WfmHwnd

    if (!TeamPresented || !IsObject(TeamGui)) {
        SetTimer(KeepTeamOnTop, 0)
        return
    }

    if (WfmHwnd && WinExist("ahk_id " WfmHwnd))
        try WinSetAlwaysOnTop(0, "ahk_id " WfmHwnd)

    try WinSetAlwaysOnTop(1, "ahk_id " TeamGui.Hwnd)
    try DllCall("SetWindowPos", "ptr", TeamGui.Hwnd, "ptr", -1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
}

CancelTeamSelector(*) {
    global TeamGui, TeamPresented
    SetTimer(KeepTeamOnTop, 0)
    try TeamGui.Destroy()
    TeamGui := 0
    TeamPresented := false
}

StartScan(*) {
    global WfmHwnd, TeamGui, ScanBusy, HelperStatus

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
        MsgBox("De opgehaalde scanner begint niet met javascript:.", "WFM Bridge Helper")
        return
    }

    oldClipboard := ClipboardAll()

    try {
        KeepTeamOnTop()
        PrepareWfmForScan(target)
        KeepTeamOnTop()

        A_Clipboard := SubStr(code, 12)
        if !ClipWait(2)
            throw Error("De scanner kon niet tijdelijk naar het klembord worden gezet.")

        ; WFM krijgt toetsenbordfocus achter het native topmost-venster.
        WinActivate("ahk_id " target)
        if !WinWaitActive("ahk_id " target, , 3)
            throw Error("Het WFM-venster kon niet actief worden gemaakt.")

        KeepTeamOnTop()
        Send("^l")
        Sleep(140)
        SendText("javascript:")
        Sleep(70)
        Send("^v")
        Sleep(160)
        Send("{Enter}")

        try HelperStatus.Text := "6-weeks scan gestart"
        Sleep(120)
        KeepTeamOnTop()
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
    ; Alleen achter de native teamkiezer wordt WFM tijdelijk groter gemaakt zodat
    ; de bestaande scanner de bekende desktop-layout ziet.
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

ResetFlow() {
    global WfmHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks
    global ChangedCandidate, ChangedTicks, TeamPresented, ScanBusy, TeamGui, HelperStatus

    SetTimer(KeepTeamOnTop, 0)
    try {
        if IsObject(TeamGui)
            TeamGui.Destroy()
    }
    TeamGui := 0
    WfmHwnd := 0
    BaselineTitle := ""
    TitleCandidate := ""
    TitleCandidateTicks := 0
    ChangedCandidate := ""
    ChangedTicks := 0
    TeamPresented := false
    ScanBusy := false
    try HelperStatus.Text := "Wacht op Rooster Log in"
}

IsEdgeWindow(hwnd) {
    try return StrLower(WinGetProcessName("ahk_id " hwnd)) = "msedge.exe"
    catch return false
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
