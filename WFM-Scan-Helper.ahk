#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; WFM-TEST - zelfstandige scan helper
; Testdoel:
; 1. Start dit script 1x.
; 2. Open WFM vanuit WFM-TEST en log normaal in.
; 3. Klik op de losse zwevende knop "WFM Scan".
; 4. Het laatst actieve Edge-venster wordt donker gemaakt.
; 5. Klik "SCAN ROOSTER". De actuele 6-weeks scanner wordt gestart
;    zonder Edge-favoriet/bookmarklet.
;
; De helper leest alleen de scanner-code uit de publieke WFM-TEST repo.
; WFM-login/wachtwoorden worden niet gelezen of opgeslagen.

SCANNER_URLS := [
    "https://svanbergen99.github.io/WFM-TEST/WFM-Planning-Scan-Send-Bookmarklet.txt",
    "https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/WFM-Planning-Scan-Send-Bookmarklet.txt"
]

global LastEdgeHwnd := 0
global OverlayGui := 0
global HelperGui := 0
global StatusText := 0

global ScannerUrls := SCANNER_URLS

BuildHelper()
SetTimer(TrackLastEdgeWindow, 200)

BuildHelper() {
    global HelperGui, StatusText

    HelperGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "WFM Scan")
    HelperGui.MarginX := 10
    HelperGui.MarginY := 10
    HelperGui.SetFont("s10 Bold", "Segoe UI")

    btn := HelperGui.AddButton("w180 h48", "WFM Scan")
    btn.OnEvent("Click", ShowOverlay)

    HelperGui.SetFont("s8 Norm", "Segoe UI")
    StatusText := HelperGui.AddText("w180 Center c666666", "Wacht op een Edge/WFM-venster")

    HelperGui.OnEvent("Close", (*) => ExitApp())
    HelperGui.Show("AutoSize")
}

TrackLastEdgeWindow(*) {
    global LastEdgeHwnd, StatusText

    hwnd := WinExist("A")
    if !hwnd
        return

    try processName := WinGetProcessName("ahk_id " hwnd)
    catch
        return

    if (StrLower(processName) != "msedge.exe")
        return

    LastEdgeHwnd := hwnd

    try title := WinGetTitle("ahk_id " hwnd)
    catch title := "Edge"

    if (StrLen(title) > 30)
        title := SubStr(title, 1, 30) "…"

    try StatusText.Text := "Gekoppeld aan: " title
}

ShowOverlay(*) {
    global LastEdgeHwnd, OverlayGui

    if (!LastEdgeHwnd || !WinExist("ahk_id " LastEdgeHwnd)) {
        MsgBox("Ik heb nog geen Edge-venster gezien.`n`nOpen WFM in Edge, klik eenmaal in het WFM-venster en probeer daarna opnieuw.", "WFM Scan")
        return
    }

    try WinGetPos(&x, &y, &w, &h, "ahk_id " LastEdgeHwnd)
    catch {
        MsgBox("Het gekoppelde Edge-venster kon niet worden gevonden.", "WFM Scan")
        return
    }

    if (w < 500 || h < 350) {
        MsgBox("Het gekoppelde Edge-venster is te klein om de scan-overlay te tonen.", "WFM Scan")
        return
    }

    try {
        if IsObject(OverlayGui)
            OverlayGui.Destroy()
    }

    OverlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "WFM Scan Overlay")
    OverlayGui.BackColor := "111827"

    titleY := Round(h * 0.30)
    buttonY := Round(h * 0.46)

    OverlayGui.SetFont("s24 Bold cFFFFFF", "Segoe UI")
    OverlayGui.AddText("x0 y" titleY " w" w " Center BackgroundTrans", "WFM ROOSTER")

    OverlayGui.SetFont("s11 Norm cD1D5DB", "Segoe UI")
    OverlayGui.AddText("x0 y" (titleY + 48) " w" w " Center BackgroundTrans", "WFM is ingelogd? Start dan de persoonlijke 6-weeks scan.")

    OverlayGui.SetFont("s18 Bold c111827", "Segoe UI")
    scanButton := OverlayGui.AddButton("x" Round((w - 340) / 2) " y" buttonY " w340 h82", "SCAN ROOSTER")
    scanButton.OnEvent("Click", StartScan)

    OverlayGui.SetFont("s10 Norm c111827", "Segoe UI")
    cancelButton := OverlayGui.AddButton("x" Round((w - 180) / 2) " y" (buttonY + 104) " w180 h42", "Annuleren")
    cancelButton.OnEvent("Click", CancelOverlay)

    OverlayGui.OnEvent("Escape", CancelOverlay)
    OverlayGui.Show("x" x " y" y " w" w " h" h)

    ; Bijna volledig donker, maar knop/tekst blijven zichtbaar.
    try WinSetTransparent(242, "ahk_id " OverlayGui.Hwnd)
}

CancelOverlay(*) {
    global OverlayGui
    try OverlayGui.Destroy()
    OverlayGui := 0
}

StartScan(*) {
    global LastEdgeHwnd, OverlayGui

    target := LastEdgeHwnd

    try OverlayGui.Hide()

    if (!target || !WinExist("ahk_id " target)) {
        MsgBox("Het WFM/Edge-venster is niet meer beschikbaar.", "WFM Scan")
        return
    }

    try code := DownloadScanner()
    catch Error as err {
        MsgBox("De scanner-code kon niet worden geladen.`n`n" err.Message, "WFM Scan")
        try OverlayGui.Show()
        return
    }

    if (SubStr(code, 1, 11) != "javascript:") {
        MsgBox("De opgehaalde scanner begint niet met javascript:.`nDe scan is voor de veiligheid niet gestart.", "WFM Scan")
        try OverlayGui.Show()
        return
    }

    oldClipboard := ClipboardAll()

    try {
        ; Edge verwijdert soms een volledig geplakte javascript:-URL.
        ; Daarom typen we het protocol zelf en plakken alleen de code erachter.
        A_Clipboard := SubStr(code, 12)
        if !ClipWait(2)
            throw Error("De scanner kon niet tijdelijk naar het klembord worden gezet.")

        WinActivate("ahk_id " target)
        if !WinWaitActive("ahk_id " target, , 3)
            throw Error("Het WFM-venster kon niet actief worden gemaakt.")

        Send("^l")
        Sleep(150)
        SendText("javascript:")
        Sleep(80)
        Send("^v")
        Sleep(180)
        Send("{Enter}")
        Sleep(500)

        ; Vanaf hier draait dezelfde scanner als de oude Edge-favoriet:
        ; 6 weeks -> OK -> scan -> postMessage -> WFM sluit na ACK.
    }
    catch Error as err {
        MsgBox("De scanner kon niet in Edge worden gestart.`n`n" err.Message, "WFM Scan")
        try OverlayGui.Show()
    }
    finally {
        A_Clipboard := oldClipboard
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
