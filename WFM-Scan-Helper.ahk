#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - native teamkiezer + WFM scan helper
; v7: GEEN herkenning of detectie meer voor het tonen van de teamkiezer.
; Zodra deze helper start, staat "Selecteer je team" direct in beeld en blijft
; het venster boven andere vensters staan. KCD Team 3 start de bestaande scan.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

TEST_PAGE_TITLE := "Rooster WFM Test"
HELPER_VERSION := "v7 direct zichtbaar"

global ScannerUrls := SCANNER_URLS
global TestPageTitle := TEST_PAGE_TITLE
global HelperVersion := HELPER_VERSION

global WfmHwnd := 0
global TeamPresented := false
global TeamDismissed := false
global ScanBusy := false

global HelperGui := 0
global HelperStatus := 0
global TeamGui := 0
global TeamTitle := 0
global TeamHint := 0
global TeamDropdown := 0

BuildHelper()
ShowNativeTeamSelector(false)
SetTimer(MonitorFlow, 200)

BuildHelper() {
    global HelperGui, HelperStatus, HelperVersion

    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Bridge Helper " HelperVersion)
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10

    HelperGui.SetFont("s9 Bold", "Segoe UI")
    HelperStatus := HelperGui.AddText("w260 Center", "Teamkiezer wordt geopend")

    HelperGui.SetFont("s8 Norm", "Segoe UI")
    btn := HelperGui.AddButton("xm w260 h36", "Toon teamkiezer")
    btn.OnEvent("Click", ReopenTeamSelector)

    HelperGui.AddText("xm w260 Center c666666", HelperVersion)
    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

ReopenTeamSelector(*) {
    global TeamDismissed
    TeamDismissed := false
    ShowNativeTeamSelector(true)
}

MonitorFlow(*) {
    global TeamPresented, TeamDismissed, ScanBusy, WfmHwnd, HelperStatus

    ; Geen pagina-, login-, titel- of beeldherkenning meer.
    ; Als de popup niet handmatig is gesloten, hoort hij altijd zichtbaar te zijn.
    if (!TeamPresented && !TeamDismissed && !ScanBusy)
        ShowNativeTeamSelector(false)

    ; De bestaande WFM-scanner sluit WFM na de ACK.
    ; Zodra dat gebeurt sluiten we ook de native teamkiezer.
    if (ScanBusy && WfmHwnd && !WinExist("ahk_id " WfmHwnd)) {
        ScanBusy := false
        TeamDismissed := true
        WfmHwnd := 0
        CloseTeamSelector(false)
        try HelperStatus.Text := "Scan klaar"
        return
    }

    if TeamPresented
        KeepTeamOnTop()
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

        if (w < 250 || h < 250)
            continue

        score := 0
        lower := StrLower(title)

        if InStr(lower, "wfm")
            score += 160
        if InStr(lower, "genesys")
            score += 160
        if InStr(lower, "workforce")
            score += 140
        if InStr(lower, "schedule")
            score += 70
        if InStr(lower, "login")
            score += 50

        ; De WFM-loginpopup is expres compact.
        if (w >= 320 && w <= 650 && h >= 380 && h <= 750)
            score += 150

        if (hwnd = active)
            score += 20

        if (score > bestScore) {
            bestScore := score
            best := hwnd
        }
    }

    return best
}

ShowNativeTeamSelector(force := false) {
    global TeamPresented, TeamDismissed, TeamGui, TeamTitle, TeamHint, TeamDropdown, HelperStatus

    if TeamPresented {
        KeepTeamOnTop()
        try WinActivate("ahk_id " TeamGui.Hwnd)
        return
    }

    try {
        if IsObject(TeamGui)
            TeamGui.Destroy()
    }

    TeamGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "Rooster Teamkeuze")
    TeamGui.BackColor := "111827"
    TeamGui.MarginX := 36
    TeamGui.MarginY := 30

    TeamGui.SetFont("s20 Bold cFFFFFF", "Segoe UI")
    TeamTitle := TeamGui.AddText("w340 Center BackgroundTrans", "Selecteer je team")

    TeamGui.SetFont("s10 Norm cCBD5E1", "Segoe UI")
    TeamHint := TeamGui.AddText("xm y+12 w340 Center BackgroundTrans", "Log in bij WFM en kies daarna je team.")

    TeamGui.SetFont("s12 Norm c111827", "Segoe UI")
    TeamDropdown := TeamGui.AddDropDownList("xm y+24 w340 Choose1", ["Kies team", "KCD Team 3"])
    TeamDropdown.OnEvent("Change", TeamChanged)
    TeamGui.OnEvent("Escape", (*) => CloseTeamSelector(true))

    ; Rechtsboven zodat de Rooster Log in-knop vrij blijft.
    try {
        primary := MonitorGetPrimary()
        MonitorGetWorkArea(primary, &ml, &mt, &mr, &mb)
        w := 420
        h := 235
        x := Max(ml + 12, mr - w - 28)
        y := mt + 54
        TeamGui.Show("x" x " y" y " w" w " h" h)
    } catch {
        TeamGui.Show("w420 h235")
    }

    TeamPresented := true
    TeamDismissed := false
    KeepTeamOnTop()
    SetTimer(KeepTeamOnTop, 150)

    try DllCall("SetForegroundWindow", "ptr", TeamGui.Hwnd)
    try WinActivate("ahk_id " TeamGui.Hwnd)
    try HelperStatus.Text := "Teamkiezer zichtbaar"
}

TeamChanged(ctrl, *) {
    global ScanBusy, WfmHwnd, TeamHint, HelperStatus

    if (ctrl.Text != "KCD Team 3" || ScanBusy)
        return

    WfmHwnd := FindWfmWindow()

    if (!WfmHwnd || !WinExist("ahk_id " WfmHwnd)) {
        try TeamHint.Text := "Open eerst WFM via Rooster Log in en log volledig in."
        try ctrl.Choose(1)
        try HelperStatus.Text := "WFM nog niet gevonden"
        return
    }

    ScanBusy := true
    ShowLoadingState()
    SetTimer(StartScan, -80)
}

ShowLoadingState() {
    global TeamTitle, TeamHint, TeamDropdown, HelperStatus

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

CloseTeamSelector(dismiss := true) {
    global TeamGui, TeamPresented, TeamDismissed

    SetTimer(KeepTeamOnTop, 0)
    try {
        if IsObject(TeamGui)
            TeamGui.Destroy()
    }
    TeamGui := 0
    TeamPresented := false
    if dismiss
        TeamDismissed := true
}

StartScan(*) {
    global WfmHwnd, ScanBusy, HelperStatus, TeamHint, TeamDropdown

    target := WfmHwnd
    if (!target || !WinExist("ahk_id " target)) {
        target := FindWfmWindow()
        WfmHwnd := target
    }

    if (!target || !WinExist("ahk_id " target)) {
        ScanBusy := false
        try TeamHint.Text := "WFM is niet beschikbaar. Open WFM, log in en probeer opnieuw."
        try TeamDropdown.Visible := true
        try TeamDropdown.Choose(1)
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
        try TeamHint.Text := "Scan kon niet starten. Probeer opnieuw."
        try TeamDropdown.Visible := true
        try TeamDropdown.Choose(1)
        MsgBox("De scanner kon niet in WFM worden gestart.`n`n" err.Message, "WFM Bridge Helper")
    }
    finally {
        A_Clipboard := oldClipboard
    }
}

PrepareWfmForScan(target) {
    ; Voor de scan vergroten we WFM achter de native teamkiezer naar desktop-layout.
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
