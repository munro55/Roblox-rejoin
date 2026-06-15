#Requires AutoHotkey v2.0

; === VERSION ===
CurrentVersion := "1.0"
VersionURL := "https://gist.githubusercontent.com/munro55/f59c320f55517a9fb9d50fdf8da1e8f5/raw/421df3421f75a068a795b79451668427776c024c/gistfile1.txt"
DownloadURL := "https://raw.githubusercontent.com/munro55/Roblox-rejoin/refs/heads/main/rejoin.ahk"

; === CONFIGURATION ===
RejoinDelay := 5000
ConfigFile := A_ScriptDir . "\rejoin_config.ini"

; === LOAD SAVED LINK ===
PrivateServerLink := ""
if FileExist(ConfigFile)
    PrivateServerLink := IniRead(ConfigFile, "Settings", "Link", "")

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

MyGui.Add("Text", "xm", "Status:")
StatusLabel := MyGui.Add("Text", "w400 cGreen", "Waiting to start...")

MyGui.Add("Text", "xm", "Roblox Process:")
ProcessLabel := MyGui.Add("Text", "w400 cGray", "Unknown")

MyGui.Add("Text", "xm", "Last Checked:")
LastCheckedLabel := MyGui.Add("Text", "w400 cGray", "Not yet")

MyGui.Add("Text", "w400 0x10 xm")

ToggleBtn := MyGui.Add("Button", "xm w90", "Start")
ToggleBtn.OnEvent("Click", ToggleMonitor)

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
    global DownloadURL
    UpdateBtn.Text := "Downloading..."
    UpdateBtn.Opt("Disabled")
    try {
        TempFile := A_Temp . "\rejoin_update.ahk"
        Download(DownloadURL, TempFile)
        FileCopy(TempFile, A_ScriptFullPath, 1)
        FileDelete(TempFile)
        MsgBox("Update downloaded! The script will now restart.", "Updated!", 64)
        Reload()
    } catch {
        MsgBox("Update failed! Check your internet connection.", "Error", 48)
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
    global PrivateServerLink, RejoinDelay, Monitoring

    LastCheckedLabel.Value := FormatTime(, "hh:mm:ss tt")

    if ProcessExist("RobloxPlayerBeta.exe") {
        ProcessLabel.Value := "Running ✓"
        ProcessLabel.Opt("cGreen")
    } else {
        ProcessLabel.Value := "Not Running ✗"
        ProcessLabel.Opt("cRed")
        StatusLabel.Value := "Roblox closed! Rejoining..."
        StatusLabel.Opt("cFF8C00")

        SetTimer(CheckRoblox, 0)
        Sleep(RejoinDelay)

        PrivateServerLink := LinkBox.Value
        Run(PrivateServerLink)

        StatusLabel.Value := "Launched! Waiting 30s..."
        StatusLabel.Opt("cBlue")
        Sleep(30000)

        if Monitoring {
            StatusLabel.Value := "Monitoring..."
            StatusLabel.Opt("cGreen")
            SetTimer(CheckRoblox, 10000)
        }
    }
}
