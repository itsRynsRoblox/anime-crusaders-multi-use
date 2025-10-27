#Requires AutoHotkey v2.0

global challengeMap := ""

StartChallenge(maxAttempts := 5) {
    global challengeMap
    attempts := 0

    if (ModeConfigurations.Value) {
        LoadUnitSettingsByMode("Challenge")
    }

    if (ChallengeTeamSwap.Value) {
        SwapTeam(true)
    }

    while (attempts < maxAttempts && !(ok := isMenuOpen("Matchmaking"))) {
        WalkToChallengeRoom()
        attempts += 1
    }

    if (attempts >= maxAttempts) {
        AddToLog("Failed to start challenge after " attempts " attempts. Giving up.")
        SetChallengeCooldown()
        if (ChallengeTeamSwap.Value) {
            SwapTeam(false)
        }
        if (ModeConfigurations.Value) {
            LoadUnitSettingsByMode(ModeDropdown.Text)
        }
        return StartSelectedMode()
    }

    AddToLog("Starting Challenge")
    FixClick(330, 350) ; click play here
    Sleep(500)
    challengeMap := DetectMapForChallenge()
    FixClick(410, 525) ; click play
    SetChallengeCooldown()
    RestartStage()
}

WalkToChallengeRoom() {
    Teleport("Challenge")
    Walk("d", 10000)
    Walk("w", 5000)
}

TimeForChallenge() {
    return AutoChallenge.Value && !IsChallengeOnCooldown() && ModeDropdown.Text != "Custom"
}

GetTeam(map) {
    switch map {
        case "1": return { x: 535, y: 300, scrolls: 0 }
        case "2": return { x: 535, y: 365, scrolls: 0 }
        case "3": return { x: 535, y: 435, scrolls: 0 }
        case "4": return { x: 535, y: 360, scrolls: 1 }
        case "5": return { x: 535, y: 425, scrolls: 1 }
    }
}

SwapTeam(forChallenge := true) {
    CloseLeaderboard()
    Sleep(500)
    SendInput("K") ; open units
    Sleep(750)
    FixClick(610, 245) ; open team menu
    Sleep(750)

    Team := GetTeam(forChallenge ? ChallengeTeam.Value : NormalTeam.Value)
    if !Team {
        return false
    }

    ; Scroll map if needed
    if Team.scrolls > 0 {
        MouseMove(538, 263)
        Scroll(Team.scrolls, 'WheelDown', 250)
    }

    Sleep(1000)
    FixClick(Team.x, Team.y)
    Sleep(1000)
    FixClick(574, 220) ; close team menu
    Sleep(750)
    SendInput("K")
    return true
}

DetectMapForChallenge() {
    AddToLog("Identifying map for challenge...")
    startTime := A_TickCount
    maxWait := 5000
    loop {
        ; Check if we waited more than maxWait for votestart
        if (A_TickCount - startTime > maxWait) {
            AddToLog("Could not detect map after 5 seconds.")
            return "no map found"
        }

        mapPatterns := Map(
            "Planet Namak", PlanetNamak,
            "Marine's Ford", MarinesFord,
            "Karakura Town", KarakuraTown,
            "Shibuya", Shibuya,
            "Demon District", DemonDistrict
        )

        for mapName, pattern in mapPatterns {
            if (ok := FindText(&X, &Y, 28, 213, 234, 258, 0.10, 0.10, pattern)) {
                AddToLog("Detected map: " mapName)
                return mapName
            }
        }

        Sleep 250
        Reconnect()
    }
}

isInChallenge() {
    global challengeMap
    if (challengeMap != "no map found" && challengeMap != "") {
        return true
    }
}

ResetChallengeMap() {
    global challengeMap
    challengeMap := ""
}

TestChallenge() {
    global challengeMap
    challengeMap := "Shibuya"
    SetChallengeCooldown()
    Sleep(500)
    MonitorStage()
}