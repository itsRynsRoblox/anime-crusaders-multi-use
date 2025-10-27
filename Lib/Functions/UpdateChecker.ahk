#Requires AutoHotkey v2.0

CheckForUpdates() {
    global repoOwner, repoName, version

    if (!UpdateChecker.Value) {
        return
    }

    ; --- Get latest release info from GitHub ---
    url := "https://api.github.com/repos/" repoOwner "/" repoName "/releases/latest"
    http := ComObject("MSXML2.XMLHTTP")
    http.Open("GET", url, false)
    http.Send()

    if (http.Status != 200) {
        AddToLog("❌ Failed to check for updates. HTTP " http.Status)
        AddToLog("Current Version: " version)
        return
    }

    response := http.responseText
    file := JSON.parse(response)
    latestVersion := file["tag_name"]
    assets := file["assets"]

    ; --- Compare versions ---
    comparison := VerCompare(version, latestVersion)

    if (comparison < 0) {
        MainUI.Opt("-AlwaysOnTop")
        ; --- Prompt the user for update ---
        MsgBoxResult := MsgBox(
            "There is a new update available!`nCurrent: " version " → Latest: v" latestVersion "`n`nDo you want to download and install it now?`n`nNote: This will create a backup of your settings folder",
            "New Update Available",
            "YesNo"
        )

        if (MsgBoxResult = "Yes") {
            AddToLog("⬇️ Accepted update, starting download...")

            if (assets.Length = 0) {
                MainUI.Opt("+AlwaysOnTop")
                AddToLog("⚠️ No release files found for version " latestVersion)
                return
            }

            ; --- Download the first asset ---
            downloadUrl := assets[1]["browser_download_url"]
            fileName := A_Temp "\" assets[1]["name"]
            Download(downloadUrl, fileName)

            ; --- Extract update ---
            extractDir := A_Temp "\update_extract"
            DirCreate(extractDir)
            try {
                psCmd := Format('powershell -NoProfile -Command "Expand-Archive -Force ' '{}' ' ' '{}' '"', fileName, extractDir)
                RunWait(psCmd, , "Hide")
                AddToLog("📦 Extracted update to: " extractDir)
            } catch Error {
                AddToLog("❌ Failed to extract ZIP")
                MainUI.Opt("+AlwaysOnTop")
                return
            }

            ; --- Backup Settings ---
            settingsDir := A_ScriptDir "\Settings"
            if DirExist(settingsDir) {
                backupDir := A_ScriptDir "\Settings_Backup_" version
                DirCreate(backupDir)
                DirCopy(settingsDir, backupDir, true)
                AddToLog("💾 Backed up settings to Settings\Settings_Backup_" version)
            }

            ; --- Install update ---
            DirCopy(extractDir, A_ScriptDir, true)
            AddToLog("✅ Update installed successfully, restarting...")
            Sleep(2000)
            ; --- Restart the script ---
            Run(A_ScriptFullPath)
            ExitApp
        } else {
            MainUI.Opt("+AlwaysOnTop")
        }

    } else if (comparison > 0) {
        AddToLog("🚨 Your version is newer than the latest published (" latestVersion ")")
    } else {
        AddToLog("✅ You are already using the latest version (" version ")")
    }
}