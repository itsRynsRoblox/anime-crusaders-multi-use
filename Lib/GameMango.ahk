#Requires AutoHotkey v2.0
#Include %A_ScriptDir%/lib/Tools/Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount
global cachedCardPriorities := Map()
LoadKeybindSettings()  ; Load saved keybinds
CheckForUpdates()
Hotkey(F1Key, (*) => moveRobloxWindow())
Hotkey(F2Key, (*) => StartMacro())
Hotkey(F3Key, (*) => Reload())
Hotkey(F4Key, (*) => TogglePause())

F5:: {

}

F6:: {

}

F7:: {
    CopyMouseCoords(true)
}

F8:: {
   Run (A_ScriptDir "\Lib\Tools\FindText.ahk")
}

StartMacro(*) {
    if (!ValidateMode()) {
        return
    }
    if (StartsInLobby(ModeDropdown.Text)) {
        if (isInLobby()) {
            StartSelectedMode()
        } else {
            AddToLog("You need to be in the lobby to start " ModeDropdown.Text " mode")
        }
    } else {
        StartSelectedMode()
    }
}

TogglePause(*) {
    Pause -1
    if (A_IsPaused) {
        AddToLog("Macro Paused")
        Sleep(1000)
    } else {
        AddToLog("Macro Resumed")
        Sleep(1000)
    }
}

CustomMode() {
    AddToLog("Starting Custom Mode")
    RestartStage()
}

HandleEndScreen(isVictory := true) {

    if (TimeForChallenge()) {
        AddToLog("[Info] Game over, starting challenge")
        return ClickReturnToLobby()
    }

    if (isInChallenge()) {
        AddToLog("[Info] Challenge over, returning to lobby")
        return ClickReturnToLobby()
    }

    Switch ModeDropdown.Text {
        case "Event":
            HandleEventEnd()
        case "Infinity Castle":
            HandleInfinityCastleEnd(isVictory)    
        case "Portal":
            HandlePortalEnd(isVictory)    
        Default:
            HandleDefaultEnd()
    }
}

HandleDefaultEnd() {
    global lastResult

    if (NextLevelBox.Value) {
        if (lastResult = "win") {
            AddToLog("[Info] Game over, starting next level")
            ClickNextLevel()
            return RestartStage()
        }
    }
    else if (Matchmaking.Value && ModesWithMatchmaking(ModeDropdown.Text)) {
            AddToLog("[Info] Game over, returning to lobby for matchmaking")
            return ClickReturnToLobby()
        } else {
            AddToLog("[Info] Game over, restarting stage")
            ClickReplay()
            return RestartStage()
        }
}

MonitorStage() {
    global Wins, loss, stageStartTime

    lastClickTime := A_TickCount

    ; Initial anti-AFK click
    FixClick(400, 500)

    Loop {
        Sleep(250)

        ; --- Anti-AFK ---
        if ((A_TickCount - lastClickTime) >= 10000) {
            FixClick(400, 500)
            lastClickTime := A_TickCount
        }

        ; --- Check for progression or special cases ---
        if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
            CheckForCardSelection()
        }

        ; --- Check for wave 50 ---
        HandleNuke()

        ; --- Fallback if disconnected ---
        Reconnect()

        CloseUnitPassives()

        ; --- Wait for XP/Results screen ---
        if (!isMenuOpen("End Screen"))
            continue

        ; --- Handle Auto Ability ---
        if (ActiveAbilityEnabled()) {
            SetTimer(CheckAutoAbility, 0)
        }

        if (NukeUnitSlotEnabled.Value) {
            ClearNuke()
        }

        ; --- Close Menus ---
        CloseMenu("Unit Manager")

        ; --- Endgame Handling ---
        AddToLog("Checking win/loss status")
        Sleep(1000)
        stageEndTime := A_TickCount
        stageLength := FormatStageTime(stageEndTime - stageStartTime)
        result := true

        if (GetPixel(0xFF0005, 156, 151, 2, 2, 10)) {
            result := false
        }

        AddToLog((result ? "Victory" : "Defeat") " detected - Stage Length: " stageLength)

        if (WebhookEnabled.Value) {
            try {
                SendWebhookWithTime(result, stageLength)
            } catch {
                AddToLog("Error: Unable to send webhook.")
            }
        } else {
            UpdateStreak(result)
        }

        HandleEndScreen(result)
        Reconnect()
        return
    }
}

Zoom() {
    WinActivate(rblxID)
    Sleep 100
    MouseMove(400, 300)
    Sleep 100

    if (ZoomInOption.Value) {
        ; Zoom in smoothly
        Scroll(20, "WheelUp", 50)

        ; Look down
        Click
        MouseMove(400, 400)  ; Move mouse down to angle camera down
    }
    
    ; Zoom back out smoothly
    Scroll(Integer(ZoomBox.Value), "WheelDown", 50)
    
    ; Move mouse back to center
    MouseMove(400, 300)
}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        AddToLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup(usedButton := false) {
    global firstStartup

    if(!WinActivate(rblxID)) {
        WinActivate(rblxID)
    }

    if (!firstStartup) {
        if (!DoesntHaveSeamless(ModeDropdown.Text)) {
            return
        }
    }

    CloseChat()
    Sleep 750

    if (ModeDropdown.Text = "Custom" && !usedButton) {
        return
    }

    if (ZoomTech.Value) {
        Zoom()
    }

    AdjustCameraToCorrectAngle(GetMapForMode(ModeDropdown.Text))
    ;FixHalloweenAngle()
    Sleep(300)

    CloseLeaderboard(false)
    Sleep 300

    if (!StartWalk(usedButton)) {
        if (ModeDropdown.Text = "Event") {
            HandleEventMovement()
        }
    }

    if (!usedButton) {
        firstStartup := false
    }
}
    
RestartStage() {

    ; Special Cases
    DetectInfinityCastleMap()
    
    ; Wait for loading
    CheckLoaded()

    BasicSetup()

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    StartPlacingUnits(PlacementPatternDropdown.Text == "Custom" || PlaceUntilSuccessful.Value)
    
    ; Monitor stage progress
    MonitorStage()
}

Reconnect(force := false) {
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    if (FindText(&X, &Y, 202, 206, 601, 256, 0.10, 0.10, Disconnect) || force) {

        ; Wait until internet is available
        while !isConnectedToInternet() {
            AddToLog("❌ No internet connection. Waiting to reconnect...")
            Sleep(5000) ; wait 5 seconds before checking again
        }

        AddToLog("✅ Internet connection verified, attempting to reconnect...")

        if (MatchmakingFailsafe.Value) {
            TimerManager.Clear("Teleport Failsafe")
        }
        AddToLog("Disconnected! Attempting to reconnect...")
        sendDCWebhook()

        if (PrivateServerEnabled.Value) {
            psLink := PrivateServerURLBox.Value
            if (psLink != "") {
                serverCode := GetPrivateServerCode(psLink)
                deepLink := "roblox://experiences/start?placeId=107573139811370&linkCode=" serverCode
                if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
                    WinClose("ahk_exe RobloxPlayerBeta.exe")
                    Sleep(3000)
                }
                AddToLog("Connecting to your private server...")
                Run(serverCode = "" ? psLink : deepLink)
                loop {
                    if WinWait("ahk_exe RobloxPlayerBeta.exe", , 15) {
                        AddToLog("New Roblox Window Found!")
                        break
                    } else {
                        AddToLog("Waiting for new Roblox Window...")
                        Sleep(1000)
                    }
                }
            }
        } else {
            Run("roblox://placeID=107573139811370")
            while (isInLobby()) {
                Sleep(100)
            }
        }

        AddToLog("Reconnecting to " GameName "...")
        TimerManager.Start("Reconnect Failsafe", 120 * 1000)
        attempts := 0

        while (!isInLobby()) {
            if (WinExist(rblxID)) {
                WinActivate(rblxID)
                sizeDown()
            }

            if (TimerManager.HasExpired("Reconnect Failsafe")) {
                attempts++
                AddToLog("[Failsafe] Reconnection failed. Attempt: " attempts)

                ; Try to relaunch Roblox again
                TimerManager.Clear("Reconnect Failsafe")
                TimerManager.Start("Reconnect Failsafe", 120 * 1000)

                if (PrivateServerEnabled.Value) {
                    psLink := PrivateServerURLBox.Value
                    if (psLink != "") {
                        serverCode := GetPrivateServerCode(psLink)
                        deepLink := "roblox://experiences/start?placeId=107573139811370&linkCode=" serverCode
                        if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
                            WinClose("ahk_exe RobloxPlayerBeta.exe")
                            Sleep(3000)
                        }
                        AddToLog("Retrying private server connection...")
                        Run(serverCode = "" ? psLink : deepLink)
                        WinWait("ahk_exe RobloxPlayerBeta.exe", , 15)
                    }
                } else {
                    Run("roblox://placeID=107573139811370")
                    WinWait("ahk_exe RobloxPlayerBeta.exe", , 15)
                }
            }

            Sleep(1000)
        }
        TimerManager.Clear("Reconnect Failsafe")
        AddToLog("Reconnected Successfully!")
        return StartSelectedMode()
    }
}

GetPrivateServerCode(link) {
    if RegExMatch(link, "privateServerLinkCode=([\w-]+)", &m)
        return m[1]
    return ""
}

wiggle() {
    MouseMove(1, 1, 5, "R")
    Sleep(30)
    MouseMove(-1, -1, 5, "R")
}

CheckLobby() {
    global firstStartup
    loop {
        Sleep 1000
        if (isInLobby()) {
            break
        }
        Reconnect()
    }
    isTimeForChallenge := TimeForChallenge()
    AddToLog("[Info] Returned to lobby, " (isTimeForChallenge ? "starting challenge" : "restarting selected mode"))
    firstStartup := true
    if (AutoChallenge.Value && !isTimeForChallenge && isInChallenge) {
        if (ChallengeTeamSwap.Value) {
            SwapTeam(false)
        }
        if (ModeConfigurations.Value) {
            LoadUnitSettingsByMode(ModeDropdown.Text)
        }
    }
    ResetInfinityCastleMap()
    ResetChallengeMap()
    return StartSelectedMode()
}

CheckLoaded() {
    loop {
        Reconnect()
        
        if (ok := FindText(&X, &Y, 59, 585, 95, 621, 0.10, 0.10, IngameQuests)) {
            AddToLog("Successfully Loaded In")
            if (MatchmakingFailsafe.Value) {
                TimerManager.Clear("Teleport Failsafe")
            }
            break
        }

        Sleep(500)
    }
}

StartedGame() {
    global alreadyNuked
    AddToLog("Game started")
    global stageStartTime := A_TickCount
    alreadyNuked := false
    HandleNuke()
}

StartSelectedMode() {

    if (StartsInLobby(ModeDropdown.Text)) {
        CloseLobbyPopups()
    }

    if (AutoChallenge.Value) {
        if (TimeForChallenge()) {
            AddToLog("[Auto Challenge] It's time for a challenge!")
            StartChallenge()
        }
    }

    switch (ModeDropdown.Text) {
        case "Story":
            StartStoryMode()
        case "Legend Stage":
            StartLegendStages()
        case "Raid":
            StartRaidMode()
        case "Event":
            StartEvent()
        case "Portal":
            StartPortals()
        case "Infinity Castle":
            StartInfinityCastle()
        case "Custom":
            CustomMode()
    }
}

ValidateMode() {
    if (ModeDropdown.Text = "") {
        AddToLog("Please select a gamemode before starting the macro!")
        return false
    }
    if (!confirmClicked) {
        AddToLog("Please click the confirm button before starting the macro!")
        return false
    }
    return true
}

GetNavKeys() {
    return StrSplit(FileExist("Settings\UINavigation.txt") ? FileRead("Settings\UINavigation.txt", "UTF-8") : "\,#,}", ",")
}

HandleStageEnd() {
    AddToLog("Stage ended during upgrades, proceeding to results")
    ResetPlacementTracking()
    return MonitorStage()
}

CheckForStartButton() {
    return FindText(&X, &Y, 319, 536, 396, 558, 0.10, 0.10, StartButton)
}

HandleStartButton() {
    if (CheckForStartButton()) {
        AddToLog("Start button found, clicking to start stage")
        FixClick(355, 515) ; Click the start button
        Sleep(500)
    }
}

StartsInLobby(ModeName) {
    ; Array of modes that usually start in lobby
    static modes := ["Story", "Legend Stage", "Raid", "Event", "Portal", "Infinity Castle"]

    ; Check if current mode is in the array
    for mode in modes {
        if (mode = ModeName)
            return true
    }
    return false
}

isMenuOpen(name := "") {
    if (name = "Unit Manager") {
        return GetPixel(0x00CBFF, 773, 71, 2, 2, 5)
    }
    else if (name = "Raids") {
        return FindText(&X, &Y, 546, 456, 633, 479, 0.20, 0.20, Raids)
    }
    else if (name = "Story") {
        return FindText(&X, &Y, 546, 454, 634, 479, 0.20, 0.20, StoryFailsafe)
    }
    else if (name = "End Screen") {
        return FindText(&X, &Y, 85, 361, 151, 383, 0.20, 0.20, Results)
    }
    else if (name = "Matchmaking") {
        return FindText(&X, &Y, 231, 247, 315, 287, 0.20, 0.20, JoinMatchmaking)
    }
    else if (name = "Gates") {
        return FindText(&X, &Y, 136, 193, 246, 234, 0.20, 0.20, GateUI)
    }
    else if (name = "Spirit Invasion") {
        return GetPixel(0xDE36E0, 260, 176, 2, 2, 5)
    }
    else if (name = "Infinity Castle") {
        return FindText(&X, &Y, 444, 439, 610, 475, 0.20, 0.20, InfinityCastleUI)
    }
    else if (name = "Halloween") {
        return FindText(&X, &Y, 494, 199, 616, 223, 0.20, 0.20, HalloweenUI)
    }
    else if (name = "Card Selection") {
        return FindText(&X, &Y, 352, 432, 452, 456, 0.20, 0.20, CardSelection) 
        || FindText(&X, &Y, 352, 432, 452, 456, 0.20, 0.20, CardSelectionHighlighted)
    }
    else if (name = "Stage Info") {
        return GetPixel(0xFFE700, 659, 76, 2, 2, 5)
    }
    else if (name = "Unit Passives") {
        return GetPixel(0xFFFFFF, 576, 179, 2, 2, 5)
    }
}