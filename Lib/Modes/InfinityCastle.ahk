#Requires AutoHotkey v2.0

global castleMap := ""

StartInfinityCastle() {

    while !(ok := isMenuOpen("Infinity Castle")) {
        WalkToInfinityCastle()
    }

    FixClick(530, 455) ; Enter Infinity Castle

    while (isInLobby()) {
        Sleep(100)
    }
    RestartStage()
}

WalkToInfinityCastle() {
    Teleport("Challenge")
    Walk("a", 3700)
    Walk("w", 6500)
    Walk("d", 4000)
    Walk("w", 800)
    Walk("d", 500)
}

ClickNextRoom(testing := false) {
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

DetectMapForInfinityCastle() {
    global castleMap
    if (ModeDropdown.Text != "Infinity Castle" or isInChallenge()) {
        return
    }
    AddToLog("Identifying map for Infinity Castle...")
    OpenMenu("Stage Info")
    startTime := A_TickCount
    maxWait := 5000
    loop {
        ; Check if we waited more than maxWait for votestart
        if (A_TickCount - startTime > maxWait) {
            AddToLog("Could not detect map after 5 seconds.")
            return "no map found"
        }

        mapPatterns := Map(
            "Planet Namak", PlanetNamakInfinityCastle,
            "Marine's Ford", MarinesFordInfinityCastle,
            "Karakura Town", KarakuraTownInfinityCastle,
            "Shibuya", ShibuyaInfinityCastle,
            "Demon District", DemonDistrictInfinityCastle
        )

        for mapName, pattern in mapPatterns {
            if (ok := FindText(&X, &Y, 552, 132, 799, 221, 0.10, 0.10, pattern)) {
                AddToLog("Detected map: " mapName)
                castleMap := mapName
                CloseMenu("Stage Info")
                return mapName
            }
        }
        Sleep 250
        Reconnect()
    }
}

ResetInfinityCastleMap() {
    global castleMap
    castleMap := ""
}

isInInfinityCastle() {
    return castleMap != "" && castleMap != "no map found"
}

DetectInfinityCastleMap() {
    global castleMap
    if (ModeDropdown.Text != "Infinity Castle" or isInChallenge()) {
        return
    }
    AddToLog("Trying to determine map for Infinity Castle...")
    startTime := A_TickCount

    loop {
        if (A_TickCount - startTime > 300000) {
            if (ok := FindText(&X, &Y, 59, 585, 95, 621, 0.10, 0.10, IngameQuests)) {
                AddToLog("Loaded in before map detected, attempting failsafe...")
                return DetectMapForInfinityCastle()
            }
            return "no map found"
        }

        loadingScreens := Map(
            "Planet Namak", [PlanetNamakLoadingScreen],
            "Marine's Ford", [MarinesFordLoadingScreen],
            "Karakura Town", [KarakuraTownLoadingScreen],
            "Shibuya", [ShibuyaLoadingScreen],
            "Demon District", [DemonDistrictLoadingScreen]
        )

        for mapName, patterns in loadingScreens {
            try {
                for pattern in patterns {  ; Iterate through multiple images for each map
                    if (ok := ImageSearch(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 " pattern)) {
                        AddToLog("Detected Map: " mapName)
                        castleMap := mapName
                        return mapName
                    }
                }
            } catch {
                if (debugMessages) {
                    AddToLog("Error occurred during map detection.")
                }
            }
        }

        Sleep 250
        Reconnect()
    }
}