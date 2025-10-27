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

    ; --- Read release title and description (changelog) ---
    releaseTitle := file.Has("name") ? file["name"] : latestVersion
    if file.Has("body") && file["body"] != ""
        releaseNotes := file["body"]
    else
        releaseNotes := "(No changelog or description provided for this release.)"

    ; Clean up for readability
    releaseNotes := StrReplace(releaseNotes, "`r", "")
    releaseNotes := StrReplace(releaseNotes, "`n`n", "`n")

    ; --- Compare versions ---
    comparison := VerCompare(version, latestVersion)

    if (comparison < 0) {
        MainUI.Opt("-AlwaysOnTop")

        ; Truncate long changelog for readability
        if StrLen(releaseNotes) > 1200
            releaseNotes := SubStr(releaseNotes, 1, 1200) "`n... (truncated)"

        ; --- Prompt user for update ---
        msg :=
            (
                "Current: " version " → Latest: v" latestVersion
                "`n`n" releaseNotes
                "`n`nDo you want to download and install it now?"
                "`n`nNote: Your Settings folder will be backed up and preserved."
            )

        MsgBoxResult := MsgBox(msg, "New Update Available", "YesNo")

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

            ; --- Create a unique script-local temp extraction folder ---
            extractDir := A_ScriptDir "\update_extract_" A_TickCount
            DirCreate(extractDir)

            ; --- Extract update ZIP to this folder ---
            psCmd := Format('powershell -NoProfile -Command "Expand-Archive -Force ' '{}' ' ' '{}' '"', fileName,
                extractDir)
            RunWait(psCmd, , "Hide")

            ; --- Backup user Settings ---
            settingsDir := A_ScriptDir "\Settings"
            if DirExist(settingsDir) {
                backupDir := A_ScriptDir "\Settings_Backup_" version
                DirCreate(backupDir)
                DirCopy(settingsDir, backupDir, true)
                AddToLog("💾 Backed up settings to " backupDir)
            }

            ; --- Copy all update files except overwrite Settings ---
            loop files, extractDir "\*", "D"  ; Directories
            {
                if (A_LoopFileName = "Settings") {
                    ; Copy each file inside Settings only if it doesn't already exist
                    loop files, A_LoopFileFullPath "\*", "F" {
                        relPath := StrReplace(A_LoopFileFullPath, extractDir "\Settings\", "")
                        destFile := settingsDir "\" relPath
                        if !FileExist(destFile)
                            FileCopy(A_LoopFileFullPath, destFile)
                    }
                    continue
                }

                dest := A_ScriptDir "\" A_LoopFileName
                DirCopy(A_LoopFileFullPath, dest, true)
            }

            ; Copy top-level files
            loop files, extractDir "\*", "F" {
                ; Skip any files that would go into Settings
                if !InStr(A_LoopFileFullPath, extractDir "\Settings\")
                    FileCopy(A_LoopFileFullPath, A_ScriptDir "\" A_LoopFileName, true)
            }

            ; --- Clean up temp extraction folder ---
            DirDelete(extractDir, true)
            AddToLog("✅ Update installed successfully")

            Sleep(2000)
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