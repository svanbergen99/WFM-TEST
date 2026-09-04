#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - native teamkiezer + WFM scan helper
; v4: zoekt WFM zelf op tussen alle Edge-vensters en heeft een harde fallback.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

TEST_PAGE_TITLE := "Rooster WFM Test"
HELPER_VERSION := "v4 native"

global ScannerUrls := SCANNER_URLS
global TestPageTitle := TEST_PAGE_TITLE
global HelperVersion := HELPER_VERSION

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
    global HelperGui, HelperStatus, HelperVersion

    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper " HelperVersion)
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10

    HelperGui.SetFont("s9 Bold", "Segoe UI")
    HelperStatus := HelperGui.AddText("w250 Center", "Wacht op Rooster Log in")

    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w250 h36", "Kies team NU (test/fallback)")
    btn.OnEvent("Click", FallbackTeamSelector)

    HelperGui.AddText("xm w250 Center c666666", HelperVersion)
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

FallbackTeamSelector(*) {
    global WfmHwnd, HelperStatus

    candidate := FindWfmWindow()
    if !candidate {
        MsgBox("Ik kan geen WFM Edge-venster vinden.`n`nLaat het WFM-venster open staan en klik daarna opnieuw op deze testknop.", "WFM Bridge Helper")
        return
    }

    WfmHwnd := candidate
    ResetLoginDetection(false)
    try HelperStatus.Text := "WFM gevonden; teamkiezer openen"
    ShowNativeTeamSelector(true)
}

MonitorWfm(*) {
    global WfmHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks
    global ChangedCandidate, ChangedTicks, TeamPresented, HelperStatus

    if (WfmHwnd && !WinExist("ahk_id " WfmHwnd)) {
        ResetFlow()
        return
    }

    if !WfmHwnd {
        candidate := FindWfmWindow()
        if candidate {
            WfmHwnd := candidate
            ResetLoginDetection(false)
            try HelperStatus.Text := "WFM gevonden; wacht op login"
        } else {
            return
        }
    }

    if TeamPresented {
        KeepTeamOnTop()
        return
    }

    try currentTitle := WinGetTitle("ahk_id " WfmHwnd)
    catch return

    if (BaselineTitle = "") {
        if (currentTitle = TitleCandidate) {
            TitleCandidateTicks += 1
        } else {
            TitleCandidate := currentTitle
            TitleCandidateTicks := 0
        }

        if (currentTitle != "" && TitleCandidateTicks >= 5) {
            BaselineTitle := currentTitle
            try HelperStatus.Text := "WFM login gedetecteerd; wacht op inloggen"
        }
        return
    }

    ; Normale automatische detectie: na login verandert de WFM-venstertitel.
    if (currentTitle != BaselineTitle && currentTitle != "") {
        if (currentTitle = ChangedCandidate) {
            ChangedTicks += 1
        } else {
            ChangedCandidate := currentTitle
            ChangedTicks := 0
        }

        if (ChangedTicks >= 4)
            ShowNativeTeamSelector(false)
    } else {
        ChangedCandidate := ""
        ChangedTicks := 0
    }
}

FindWfmWindow() {
    global TestPageTitle

    best := 0
    bestScore := -9999
    active := WinExist("A")

    for hwnd in WinGetList("ahk_exe msedge.exe") {
        try title := WinGetTitle("ahk_id " hwnd)
        catch continue

        if InStr(title, TestPageTitle)
            continue

        try WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        catch continue

        ; Onzichtbare/minimale browservensters overslaan.
        if (w < 250 || h < 250)
            continue

        score := 0
        lower := StrLower(title)

        if InStr(lower, "wfm")
            score += 120
        if InStr(lower, "genesys")
            score += 120
        if InStr(lower, "schedule")
            score += 50
        if InStr(lower, "login")
            score += 40

        ; Onze WFM-loginpopup is expres compact.
        if (w >= 320 && w <= 650 && h >= 380 && h <= 750)
            score += 70

        if (hwnd = active)
            score += 25

        if (score > bestScore) {
            bestScore := score
            best := hwnd
        }
    }

    return best
}

ShowNativeTeamSelector(force := false) {
    global WfmHwnd, TeamPresented, TeamGui, TeamTitle, TeamHint, TeamDropdown, HelperStatus

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd)) {
        WfmHwnd := FindWfmWindow()
    }

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd)) {
        if force
            MsgBox("Het WFM-venster kon niet worden gevonden.", "WFM Bridge Helper")
        return
    }

    try {
        if IsObject(TeamGui)
            TeamGui.Destroy()
    }

    TeamGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "Rooster Teamkeuze")
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

    ; WFM nooit topmost laten zijn.
    try WinSetAlwaysOnTop(0, "ahk_id " WfmHwnd)

    ; Altijd midden op het primaire werkgebied tonen, zodat hij niet buiten beeld kan vallen.
    try {
        primary := MonitorGetPrimary()
        MonitorGetWorkArea(primary, &ml, &mt, &mr, &mb)
        w := 420
        h := 245
        x := ml + Floor(((mr - ml) - w) / 2)
        y := mt + Floor(((mb - mt) - h) / 2)
        TeamGui.Show("x" x " y" y " w" w " h" h)
    } catch {
        TeamGui.Show("w420 h245 Center")
    }

    TeamPresented := true
    KeepTeamOnTop()
    SetTimer(KeepTeamOnTop, 120)

    try DllCall("SetForegroundWindow", "ptr", TeamGui.Hwnd)
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
    global WfmHwnd, ScanBusy, HelperStatus

    target := WfmHwnd
    if (!target || !WinExist("ahk_id " target)) {
        target := FindWfmWindow()
        WfmHwnd := target
    }

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

ResetLoginDetection(resetWindow := true) {
    global WfmHwnd, BaselineTitle, TitleCandidate, TitleCandidateTicks, ChangedCandidate, ChangedTicks, TeamPresented

    if resetWindow
        WfmHwnd := 0

    BaselineTitle := ""
    TitleCandidate := ""
    TitleCandidateTicks := 0
    ChangedCandidate := ""
    ChangedTicks := 0
    TeamPresented := false
}

ResetFlow() {
    global TeamGui, ScanBusy, HelperStatus

    SetTimer(KeepTeamOnTop, 0)
    try {
        if IsObject(TeamGui)
            TeamGui.Destroy()
    }
    TeamGui := 0
    ScanBusy := false
    ResetLoginDetection(true)
    try HelperStatus.Text := "Wacht op Rooster Log in"
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
