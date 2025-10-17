#Requires AutoHotkey v2.0
#Include %A_ScriptDir%/lib/Tools/Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount
global cachedCardPriorities := Map()
LoadKeybindSettings()  ; Load saved keybinds
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
    Switch ModeDropdown.Text {
        case "Gates":
            HandleGateEnd()  
        Default:
            HandleDefaultEnd()
    }
}

HandleDefaultEnd() {
    global lastResult

    if (TimeForChallenge()) {
        AddToLog("[Info] Game over, starting challenge")
        return ClickReturnToLobby()
    }

    if (NextLevelBox.Value) {
        if (lastResult = "win") {
            AddToLog("[Info] Game over, starting next level")
            ;ClickNextLevel()
            return RestartStage()
        }
    } else {
        if (lastResult = "win") {
            AddToLog("[Info] Game over, " (ModeDropdown.Text = "Infinity Castle" ? "starting next room" : " replaying stage"))
        } else {
            AddToLog("[Info] Game over, " (ModeDropdown.Text = "Infinity Castle" ? "retrying room" : " replaying stage"))
        }
        ClickReplay()
        return RestartStage()
    }
}

MonitorStage() {
    global Wins, loss, mode, stageStartTime

    lastClickTime := A_TickCount

    ; Initial anti-AFK click
    FixClick(400, 500)

    Loop {
        Sleep(1000)

        ; --- Anti-AFK ---
        if ((A_TickCount - lastClickTime) >= 10000) {
            FixClick(400, 500)
            lastClickTime := A_TickCount
        }

        ; --- Check for progression or special cases ---
        if (HasCards(ModeDropdown.Text)) {
            CheckForCardSelection()
        }

        CheckForPortalSelection()

        ; --- Check for wave 50 ---
        HandleNuke()

        ; --- Fallback if disconnected ---
        Reconnect()

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
        Sleep(500)
        CloseMenu("Ability Manager")

        ; --- Endgame Handling ---
        AddToLog("Checking win/loss status")
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

ClickThroughDrops() {
    AddToLog("Clicking through item drops...")
    Loop 10 {
        FixClick(400, 495)
        Sleep(500)
        if isMenuOpen("End Screen") {
            return
        }
    }
}

ChallengeMovement() {
    FixClick(765, 475)
    Sleep (500)
    FixClick(300, 415)
    SendInput ("{a down}")
    sleep (7000)
    SendInput ("{a up}")
}

PlayHere(mode := "Story") {
    if (mode = "Story") {
        FixClick(595, 468) ; click select
        Sleep(300)
        FixClick(333, 349) ; click play here
        Sleep(300)
        FixClick(410, 525) ; click play

    }
    else if (mode = "Raid") {
        FixClick(595, 468) ; click select
        Sleep(300)
    }
}

Zoom() {
    WinActivate(rblxID)
    Sleep 100
    MouseMove(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Scroll(20, "WheelUp", 50)

    ; Look down
    Click
    MouseMove(400, 400)  ; Move mouse down to angle camera down
    
    ; Zoom back out smoothly
    Scroll(Integer(ZoomBox.Value), "WheelDown", 50)
    
    ; Move mouse back to center
    MouseMove(400, 300)
}

RestartMatch() {
    FixClick(233, 10) ;click settings
    Sleep 300
    FixClick(338, 253) ;click restart match
    Sleep 3500
}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        AddToLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup(usedButton := false) {
    global firstStartup

    if (!firstStartup) {
        if (!DoesntHaveSeamless(ModeDropdown.Text)) {
            return
        }
    }

    CloseChat()
    Sleep 300
    FixClick(496, 104) ; Closes Player leaderboard
    Sleep 300

    if (ModeDropdown.Text = "Custom" && !usedButton) {
        return
    }

    Zoom()

    ; Teleport to spawn
    TeleportToSpawn()
    Sleep 300

    if (ModeDropdown.Text = "Gates" && GateMovement.Value) {
        WalkToCenterOfGateRoom()
    } else {
        WalkToCoords()
    }

    if (!usedButton) {
        firstStartup := false
    }
}
    
RestartStage() {
    
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

Reconnect(testing := false) {
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    if (FindText(&X, &Y, 202, 206, 601, 256, 0.10, 0.10, Disconnect) || testing) {
        AddToLog("Disconnected! Attempting to reconnect...")
        sendDCWebhook()

        ; Use PrivateServerURLBox.Value instead of file
        psLink := PrivateServerURLBox.Value

        ; Reconnect to PS
        if (psLink != "") {
            AddToLog("Connecting to private server...")
            Run(psLink)
        } else {
            Run("roblox://placeID=107573139811370")
        }

        Sleep 2000

        if WinExist(rblxID) {
            WinActivate(rblxID)
            Sleep 1000
        }

        AddToLog("Reconnecting to Anime Crusaders...")

        while (isInLobby()) {
            Sleep(100)
        }

        AddToLog("New session has been detected...")

        loop {
            FixClick(490, 400)
            Sleep(1000)
            if (WinExist(rblxID)) {
                WinActivate(rblxID)
            }
            if (isInLobby()) {
                AddToLog("Reconnected Successfully!")
                return StartSelectedMode()
            } else {
                Reconnect()
            }
        }
    }
}

HandleAutoAbility() {
    if !ActiveAbilityEnabled()
        return

    wiggle()

    pixelChecks := [
        {color: 0xC22725, x: 539, y: 285},
        {color: 0xC22725, x: 539, y: 268},
        {color: 0xC22725, x: 539, y: 303},

        {color: 0xC22725, x: 326, y: 284}, ; Left Side
        {color: 0xC22725, x: 326, y: 265},
        {color: 0xC22725, x: 326, y: 303}
    ]

    for pixel in pixelChecks {
        if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
            AddToLog("Enabled Auto Ability")
            FixClick(pixel.x, pixel.y)
            Sleep(500)
        }
    }
}

HandleAutoAbilityUnitManager() {
    if !ActiveAbilityEnabled()
        return

    wiggle()

    ; Grid configuration
    baseX    := 675            ; Left column starting X
    xOffset  := 95             ; Distance between columns
    baseY    := 130            ; Top row starting Y
    yStep    := 60             ; Vertical gap between rows
    numRows  := 8              ; Total rows to scan
    numCols  := 2              ; Columns per row
    color    := 0xC22725       ; Target pixel color

    ; Scan grid
    Loop numRows {
        rowIndex := A_Index - 1
        rowY := baseY + rowIndex * yStep

        Loop numCols {
            colIndex := A_Index - 1
            colX := baseX + colIndex * xOffset

            if GetPixel(color, colX, rowY, 4, 4, 20) {
                FixClick(colX, rowY)
                Sleep(100)
            }
        }
    }
}

wiggle() {
    MouseMove(1, 1, 5, "R")
    Sleep(30)
    MouseMove(-1, -1, 5, "R")
}

UpgradeUnit(x, y) {
    FixClick(x, y)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
}

CheckLobby() {
    loop {
        Sleep 1000
        if (isInLobby()) {
            break
        }
        Reconnect()
    }
    AddToLog("[Info] Returned to lobby, " (TimeForChallenge() ? "starting challenge" : "restarting selected mode"))
    return StartSelectedMode()
}

CheckLoaded() {
    loop {
        Sleep(500)
        
        if (ok := FindText(&X, &Y, 59, 585, 95, 621, 0.10, 0.10, IngameQuests)) {
            AddToLog("Successfully Loaded In")
            break
        }

        Reconnect()
    }
}

StartedGame() {
    global alreadyNuked
    Sleep(500)
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

    if (ModeDropdown.Text = "Story") {
        StartStoryMode()
    }
    else if (ModeDropdown.Text = "Raid") {
        StartRaidMode()
    }
    else if (ModeDropdown.Text = "Custom") {
        CustomMode()
    }
    else if (ModeDropdown.Text = "Portal") {
        StartPortalMode()
    }
    else if (ModeDropdown.Text = "Gates") {
        StartGates()
    }
    else if (ModeDropdown.Text = "Spirit Invasion") {
        StartSpiritInvasion()
    }
    else if (ModeDropdown.Text = "Infinity Castle") {
        StartInfinityCastle()
    }
}

FormatStageTime(ms) {
    seconds := Floor(ms / 1000)
    minutes := Floor(seconds / 60)
    hours := Floor(minutes / 60)
    
    minutes := Mod(minutes, 60)
    seconds := Mod(seconds, 60)
    
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
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

ClickUntilGone(x, y, searchX1, searchY1, searchX2, searchY2, textToFind, offsetX:=0, offsetY:=0, textToFind2:="") {
    while (ok := FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind) || 
           textToFind2 && FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind2)) {
        if (offsetX != 0 || offsetY != 0) {
            FixClick(X + offsetX, Y + offsetY)  
        } else {
            FixClick(x, y) 
        }
        Sleep(1000)
    }
}

ClickReturnToLobby(testing := false) {
    while (isMenuOpen("End Screen")) {
        pixelChecks := [{ color: 0x5AB94A, x: 108, y: 469 }]

        for pixel in pixelChecks {
            if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
                FixClick(pixel.x, pixel.y, (testing ? "Right" : "Left"))
                if (testing) {
                    Sleep(1500)
                }
            }
        }
    }
    AddToLog("[Info] Returning to lobby")
    return CheckLobby()
}

ClickReplay(testing := false) {
    while (isMenuOpen("End Screen")) {
        pixelChecks := [{ color: 0xFCE560, x: 270, y: 483 }]

        for pixel in pixelChecks {
            if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
                FixClick(pixel.x, pixel.y, (testing ? "Right" : "Left"))
                if (testing) {
                    Sleep(1500)
                }
            }
        }
    }
}

SetupForInfinite() {
    ChangeCameraMode("Follow")
    Sleep (1000)
    ZoomIn()
    Sleep (1000)
    ZoomOut()
    ChangeCameraMode("Default (Classic)")
    Sleep (1000)
    SendInput ("{a down}")
    Sleep 2000
    SendInput ("{a up}")
    KeyWait "a"
}

ChangeCameraMode(mode := "") {
    AddToLog("Changing camera mode to " mode)
    SendInput("{Escape}") ; Open Roblox Menu
    Sleep (1000)
    FixClick(205, 90) ; Click Settings
    Sleep (1000)
    loop 2 {
        FixClick(336, 209) ; Change Camera Mode
        Sleep (500)
    }
    SendInput("{Escape}") ; Open Roblox Menu
}

ZoomIn() {
    MouseMove 400, 300
    Sleep 100
    FixClick(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Loop 12 {
        Send "{WheelUp}"
        Sleep 50
    }

    ; Right-click and drag camera down
    Sleep 100
    MouseMove 400, 300  ; Ensure starting point
    Click "Right Down"
    Sleep 50
    MouseMove 400, 400, 20  ; Drag downward over 20ms
    Sleep 50
    Click "Right Up"
    Sleep 100
}

ZoomOut() {
    ; Zoom out smoothly
    Loop 10 {
        Send "{WheelDown}"
        Sleep 50
    }

    ; Move mouse back to center
    MouseMove 400, 300
}

DetectAngle(mode := "Story") {
    switch mode {
        case "Story":
            firstAngle := GetPixel(0xAC7841, 407, 92, 2, 2, 10)
            secondAngle := GetPixel(0xD77106, 407, 92, 2, 2, 10)
            if (firstAngle) {
                AddToLog("Spawn Angle: Left")
                return 1
            } else if (secondAngle) {
                AddToLog("Spawn Angle: Right")
                return 2
            } else {
                AddToLog("Spawn Angle: Unknown | Color: " PixelGetColor(407, 92) )
                return 3
            }

        case "Raid":
            firstAngle := GetPixel(0xB74D0D, 414, 49, 2, 2, 10)
            secondAngle := GetPixel(0x71250F, 414, 49, 2, 2, 10)
            if (firstAngle) {
                AddToLog("Spawn Angle: Left")
                return 1
            } else if (secondAngle) {
                AddToLog("Spawn Angle: Right")
                return 2
            } else {
                AddToLog("Spawn Angle: Unknown | Color: " PixelGetColor(414, 49) )
                return 3
            }
    }
    return 0
}

HandleStageEnd(waveRestart := false) {
    global challengeStartTime
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
    static modes := ["Story", "Raid", "Gates", "Spirit Invasion", "Infinity Castle"]
    
    ; Special case: If PortalLobby.Value is set, don't start in lobby for "Portal"
    if (ModeName = "Portal" && !PortalLobby.Value)
        return false

    ; Check if current mode is in the array
    for mode in modes {
        if (mode = ModeName)
            return true
    }
    return false
}

HasCards(ModeName) {
    ; Array of modes that have card selection
    static modesWithCards := ["Spirit Invasion"]
    
    ; Check if current mode is in the array
    for mode in modesWithCards {
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
}