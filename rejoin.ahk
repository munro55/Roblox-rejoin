#Requires AutoHotkey v2.0
#Include Gdip_Minimal.ahk

; === VERSION ===
CurrentVersion := "1.1"
VersionURL := "https://gist.githubusercontent.com/munro55/f59c320f55517a9fb9d50fdf8da1e8f5/raw/gistfile1.txt"
DownloadURL := "https://raw.githubusercontent.com/munro55/Roblox-rejoin/refs/heads/main/rejoin.ahk"
GdipDownloadURL := "https://raw.githubusercontent.com/munro55/Roblox-rejoin/refs/heads/main/Gdip_Minimal.ahk"

; === GLOBAL ERROR HANDLER ===
; Catches anything that would otherwise silently kill the script and logs it to a file + Discord
OnError(LogUnhandledError)
ErrorLogFile := A_ScriptDir . "\rejoin_errors.log"

LogUnhandledError(err, mode) {
    global ErrorLogFile
    try {
        logLine := FormatTime(, "yyyy-MM-dd HH:mm:ss") . " | " . err.Message . " | " . err.What . " | Line " . err.Line . "`n"
        FileAppend(logLine, ErrorLogFile)
        SendDiscordMessage("🛑 Script hit an unexpected error and recovered: " . err.Message)
    }
    return true  ; tell AHK we handled it, so it doesn't terminate the script
}

; === CONFIGURATION ===
RejoinDelay := 5000
ConfigFile := A_ScriptDir . "\rejoin_config.ini"

; === LOAD SAVED LINK ===
PrivateServerLink := ""
WebhookURL := ""
DiscordUserID := ""
if FileExist(ConfigFile) {
    PrivateServerLink := IniRead(ConfigFile, "Settings", "Link", "")
    WebhookURL := IniRead(ConfigFile, "Settings", "Webhook", "")
    DiscordUserID := IniRead(ConfigFile, "Settings", "DiscordID", "")
}

; === GUI SETUP ===
MyGui := Gui(, "Roblox Auto Rejoin")
MyGui.SetFont("s10", "Segoe UI")

MyGui.Add("Text",, "Private Server Link:")
LinkBox := MyGui.Add("Edit", "w400 h60 vLinkBox Multi Wrap", PrivateServerLink)

MyGui.Add("Text", "w400 h1 0x10")

SaveBtn := MyGui.Add("Button", "w90", "Save Link")
SaveBtn.OnEvent("Click", SaveLink)

CopyBtn := MyGui.Add("Button", "x+10 w90", "Copy Link")
CopyBtn.OnEvent("Click", CopyLink)

ClearBtn := MyGui.Add("Button", "x+10 w90", "Clear Link")
ClearBtn.OnEvent("Click", ClearLink)

MyGui.Add("Text", "w400 0x10 xm")

MyGui.Add("Text", "xm", "Discord Webhook URL:")
WebhookBox := MyGui.Add("Edit", "w400 vWebhookBox", WebhookURL)

MyGui.Add("Text", "xm", "Your Discord User ID (for pings):")
DiscordIDBox := MyGui.Add("Edit", "w400 vDiscordIDBox", DiscordUserID)

SaveWebhookBtn := MyGui.Add("Button", "xm w180", "Save Discord Settings")
SaveWebhookBtn.OnEvent("Click", SaveWebhookSettings)

TestWebhookBtn := MyGui.Add("Button", "x+10 w180", "Send Test Message")
TestWebhookBtn.OnEvent("Click", TestWebhook)

MyGui.Add("Text", "w400 0x10 xm")

MyGui.Add("Text", "xm", "Status:")
StatusLabel := MyGui.Add("Text", "w400 cGreen", "Waiting to start...")

MyGui.Add("Text", "xm", "Roblox Process:")
ProcessLabel := MyGui.Add("Text", "w400 cGray", "Unknown")

MyGui.Add("Text", "xm", "Last Checked:")
LastCheckedLabel := MyGui.Add("Text", "w400 cGray", "Not yet")

MyGui.Add("Text", "w400 0x10 xm")

ToggleBtn := MyGui.Add("Button", "xm w90", "Start")
ToggleBtn.OnEvent("Click", ToggleMonitor)

DebugBtn := MyGui.Add("Button", "x+10 w90", "Debug Check")
DebugBtn.OnEvent("Click", DebugCheck)

; Update button (hidden by default)
UpdateBtn := MyGui.Add("Button", "x+10 w150 Hidden", "🔔 Update Available!")
UpdateBtn.OnEvent("Click", OpenDownload)

MyGui.SetFont("s8", "Segoe UI")
VersionLabel := MyGui.Add("Text", "xm cGray", "v" . CurrentVersion . " | checking for updates...")
MyGui.Add("Text", "x340 yp cFF69B4", "made by munro")

MyGui.Show()

; === STATE ===
Monitoring := false

; === CHECK FOR UPDATES ON LAUNCH ===
CheckForUpdates()

; === FUNCTIONS ===
CheckForUpdates() {
    global CurrentVersion, VersionURL
    try {
        TempFile := A_Temp . "\munro_version.txt"
        Download(VersionURL, TempFile)
        LatestVersion := Trim(FileRead(TempFile))
        FileDelete(TempFile)

        if (LatestVersion != CurrentVersion) {
            UpdateBtn.Opt("-Hidden")
            VersionLabel.Value := "v" . CurrentVersion . " (v" . LatestVersion . " available)"
            VersionLabel.Opt("cFF8C00")
        } else {
            VersionLabel.Value := "v" . CurrentVersion . " (up to date)"
            VersionLabel.Opt("cGray")
        }
    } catch {
        VersionLabel.Value := "v" . CurrentVersion . " (update check failed)"
        VersionLabel.Opt("cGray")
    }
}

OpenDownload(*) {
    global DownloadURL, GdipDownloadURL
    UpdateBtn.Text := "Downloading..."
    UpdateBtn.Opt("Disabled")
    try {
        ; Download the main script to a temp file first
        TempFile := A_Temp . "\rejoin_update.ahk"
        Download(DownloadURL, TempFile)

        ; Download the Gdip helper library straight into the script's folder
        GdipPath := A_ScriptDir . "\Gdip_Minimal.ahk"
        TempGdip := A_Temp . "\Gdip_Minimal_update.ahk"
        Download(GdipDownloadURL, TempGdip)
        FileCopy(TempGdip, GdipPath, 1)
        FileDelete(TempGdip)

        ; Now overwrite the main script and restart
        FileCopy(TempFile, A_ScriptFullPath, 1)
        FileDelete(TempFile)
        MsgBox("Update downloaded! The script will now restart.", "Updated!", 64)
        Reload()
    } catch as e {
        MsgBox("Update failed! Check your internet connection. Error: " . e.Message, "Error", 48)
        UpdateBtn.Text := "🔔 Update Available!"
        UpdateBtn.Opt("-Disabled")
    }
}

SaveLink(*) {
    global PrivateServerLink, ConfigFile
    PrivateServerLink := LinkBox.Value
    IniWrite(PrivateServerLink, ConfigFile, "Settings", "Link")
    StatusLabel.Value := "Link saved!"
    StatusLabel.Opt("cBlue")
}

CopyLink(*) {
    A_Clipboard := LinkBox.Value
    StatusLabel.Value := "Link copied to clipboard!"
    StatusLabel.Opt("cBlue")
}

ClearLink(*) {
    LinkBox.Value := ""
    PrivateServerLink := ""
    if FileExist(ConfigFile)
        IniDelete(ConfigFile, "Settings", "Link")
    StatusLabel.Value := "Link cleared."
    StatusLabel.Opt("cRed")
}

SaveWebhookSettings(*) {
    global WebhookURL, DiscordUserID, ConfigFile
    WebhookURL := WebhookBox.Value
    DiscordUserID := DiscordIDBox.Value
    IniWrite(WebhookURL, ConfigFile, "Settings", "Webhook")
    IniWrite(DiscordUserID, ConfigFile, "Settings", "DiscordID")
    StatusLabel.Value := "Discord settings saved!"
    StatusLabel.Opt("cBlue")
}

TestWebhook(*) {
    global WebhookURL
    WebhookURL := WebhookBox.Value
    if (WebhookURL = "") {
        MsgBox("Please enter a webhook URL first!", "Missing Webhook", 48)
        return
    }
    PingText := (DiscordIDBox.Value != "") ? "<@" . DiscordIDBox.Value . "> " : ""
    SendDiscordMessage(PingText . "✅ Test message from Roblox Auto Rejoin! Webhook is working.")
    StatusLabel.Value := "Test message sent!"
    StatusLabel.Opt("cBlue")
}

; Sends a plain text message to the Discord webhook
SendDiscordMessage(text) {
    global WebhookURL
    if (WebhookURL = "")
        return
    try {
        payload := '{"content":"' . StrReplace(StrReplace(text, '\', '\\'), '"', '\"') . '"}'
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", WebhookURL, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(payload)
    } catch as e {
        ; silently fail, don't interrupt monitoring
    }
}

; Takes a screenshot and sends it to the Discord webhook with optional text
SendDiscordScreenshot(text) {
    global WebhookURL
    if (WebhookURL = "")
        return
    try {
        ShotPath := A_Temp . "\rejoin_screenshot.png"
        CaptureScreenshot(ShotPath)
        UploadScreenshotToDiscord(ShotPath, text)
        FileDelete(ShotPath)
    } catch as e {
        SendDiscordMessage("⚠️ Screenshot failed to send. Error: " . e.Message)
    }
}

; Captures the full screen and saves as PNG using the proven Gdip_All library functions
CaptureScreenshot(SavePath) {
    if FileExist(SavePath)
        FileDelete(SavePath)

    pToken := Gdip_Startup()
    try {
        pBitmap := Gdip_BitmapFromScreen()
        if (pBitmap <= 0)
            throw Error("Gdip_BitmapFromScreen failed with code " . pBitmap)

        result := Gdip_SaveBitmapToFile(pBitmap, SavePath)
        Gdip_DisposeImage(pBitmap)

        if (result != 0)
            throw Error("Gdip_SaveBitmapToFile failed with code " . result)
    } finally {
        Gdip_Shutdown(pToken)
    }

    if !FileExist(SavePath)
        throw Error("Screenshot file was not created")
}

; Uploads a screenshot file to Discord webhook using multipart form data
UploadScreenshotToDiscord(FilePath, MessageText) {
    global WebhookURL
    boundary := "----RejoinBoundary" . A_TickCount
    CRLF := Chr(13) . Chr(10)

    bodyStart := "--" . boundary . CRLF
    bodyStart .= 'Content-Disposition: form-data; name="content"' . CRLF . CRLF
    bodyStart .= MessageText . CRLF
    bodyStart .= "--" . boundary . CRLF
    bodyStart .= 'Content-Disposition: form-data; name="file"; filename="screenshot.png"' . CRLF
    bodyStart .= "Content-Type: image/png" . CRLF . CRLF

    bodyEnd := CRLF . "--" . boundary . "--" . CRLF

    ; Convert text parts to UTF-8 byte buffers (no BOM, no null terminator)
    startSize := StrPut(bodyStart, "UTF-8") - 1
    startBytes := Buffer(startSize)
    StrPut(bodyStart, startBytes, "UTF-8")

    endSize := StrPut(bodyEnd, "UTF-8") - 1
    endBytes := Buffer(endSize)
    StrPut(bodyEnd, endBytes, "UTF-8")

    ; Read the PNG file as raw bytes
    fileObj := FileOpen(FilePath, "r")
    fileSize := fileObj.Length
    fileBytes := Buffer(fileSize)
    fileObj.RawRead(fileBytes, fileSize)
    fileObj.Close()

    ; Stitch all three buffers together
    totalSize := startSize + fileSize + endSize
    fullBody := Buffer(totalSize)
    DllCall("RtlMoveMemory", "Ptr", fullBody.Ptr, "Ptr", startBytes.Ptr, "UPtr", startSize)
    DllCall("RtlMoveMemory", "Ptr", fullBody.Ptr + startSize, "Ptr", fileBytes.Ptr, "UPtr", fileSize)
    DllCall("RtlMoveMemory", "Ptr", fullBody.Ptr + startSize + fileSize, "Ptr", endBytes.Ptr, "UPtr", endSize)

    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", WebhookURL, false)
    whr.SetRequestHeader("Content-Type", "multipart/form-data; boundary=" . boundary)
    whr.Send(fullBody)

    if (whr.Status < 200 || whr.Status >= 300)
        throw Error("Discord upload failed with status " . whr.Status . ": " . whr.ResponseText)
}

DebugCheck(*) {
    foundProcesses := ""
    for proc in ComObjGet("winmgmts:").ExecQuery("Select Name from Win32_Process") {
        if InStr(proc.Name, "Roblox") {
            foundProcesses .= proc.Name . "`n"
        }
    }

    if (foundProcesses = "")
        foundProcesses := "(none found)`n"

    WindowStatus := WinExist("ahk_exe RobloxPlayerBeta.exe") ? "YES - window detected" : "NO - no window detected"

    MsgBox("Processes with 'Roblox' in the name:`n" . foundProcesses . "`nRoblox game WINDOW open? " . WindowStatus, "Debug Check", 64)
}

ToggleMonitor(*) {
    global Monitoring
    if Monitoring {
        Monitoring := false
        SetTimer(CheckRoblox, 0)
        ToggleBtn.Text := "Start"
        StatusLabel.Value := "Monitoring stopped."
        StatusLabel.Opt("cRed")
    } else {
        if (LinkBox.Value = "") {
            MsgBox("Please enter a private server link first!", "Missing Link", 48)
            return
        }
        Monitoring := true
        ToggleBtn.Text := "Stop"
        StatusLabel.Value := "Monitoring..."
        StatusLabel.Opt("cGreen")
        SetTimer(CheckRoblox, 10000)
        CheckRoblox()
    }
}

CheckRoblox() {
    global PrivateServerLink, RejoinDelay, Monitoring, DiscordUserID

    LastCheckedLabel.Value := FormatTime(, "hh:mm:ss tt")

    ; Check for an actual visible Roblox game window rather than just the process,
    ; since RobloxPlayerBeta.exe can linger in the background after closing
    RobloxWindowOpen := WinExist("ahk_exe RobloxPlayerBeta.exe")

    if RobloxWindowOpen {
        ProcessLabel.Value := "Running ✓"
        ProcessLabel.Opt("cGreen")
        return
    }

    ProcessLabel.Value := "Not Running ✗"
    ProcessLabel.Opt("cRed")
    StatusLabel.Value := "Roblox closed! Rejoining..."
    StatusLabel.Opt("cFF8C00")

    ; Stop the timer while we handle the rejoin, but GUARANTEE it restarts
    ; via the finally block below, even if something throws in between
    SetTimer(CheckRoblox, 0)

    try {
        try {
            ; Ping the user and notify that Roblox closed
            PingText := (DiscordIDBox.Value != "") ? "<@" . DiscordIDBox.Value . "> " : ""
            SendDiscordMessage(PingText . "⚠️ Roblox closed! Attempting to rejoin the private server...")
        }

        Sleep(RejoinDelay)

        PrivateServerLink := LinkBox.Value
        Run(PrivateServerLink)

        StatusLabel.Value := "Launched! Waiting 30s..."
        StatusLabel.Opt("cBlue")
        Sleep(30000)

        try {
            ; Send a plain text confirmation instead of a screenshot for now
            if WinExist("ahk_exe RobloxPlayerBeta.exe") {
                SendDiscordMessage("✅ Rejoined the private server successfully!")
            } else {
                SendDiscordMessage("❌ Rejoin attempt may have failed — Roblox window is still not open.")
            }
        }
    } finally {
        ; No matter what happened above, restart monitoring if it's still enabled
        if Monitoring {
            StatusLabel.Value := "Monitoring..."
            StatusLabel.Opt("cGreen")
            SetTimer(CheckRoblox, 10000)
        }
    }
}
