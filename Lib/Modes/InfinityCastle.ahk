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
    loop {
        if (isInGame()) {
            OpenMenu("Stage Info")
            break
        }
        Sleep 250
    }

    startTime := A_TickCount
    maxWait := 5000

    loop {
        ; Check if we waited more than maxWait for votestart
        if (A_TickCount - startTime > maxWait) {
            AddToLog("Could not detect map after 5 seconds.")
            CloseMenu("Stage Info")
            return "no map found"
        }

        mapPatterns := Map(
            "Planet Namak", PlanetNamakInfinityCastle,
            "Marine's Ford", MarinesFordInfinityCastle,
            "Karakura Town", KarakuraTownInfinityCastle,
            "Shibuya", ShibuyaInfinityCastle,
            "Demon District", DemonDistrictInfinityCastle,
            ;"Nightmare Train: Act 1", NightmareTrainAct1InfinityCastle,
            "Nightmare Train: Act 2", NightmareTrainAct2InfinityCastle,
            "Nightmare Train: Act 3", NightmareTrainAct3InfinityCastle
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
        if (isInGame()) {
            AddToLog("Loaded in before map detected, attempting failsafe...")
            return DetectMapForInfinityCastle()
        }

        if (A_TickCount - startTime > 300000) {
            AddToLog("Could not detect map after 5 minutes, reconnecting...")
            Reconnect(true)
            return
        }

        loadingScreens := Map(
            "Planet Namak", [PlanetNamakLoadingScreen],
            "Marine's Ford", [MarinesFordLoadingScreen],
            "Karakura Town", [KarakuraTownLoadingScreen],
            "Shibuya", [ShibuyaLoadingScreen],
            "Shibuya (Destroyed)", [ShibuyaDestroyedLoadingScreen],
            "Demon District", [DemonDistrictLoadingScreen],
            "Nightmare Train: Act 1", [NightmareTrainAct1LoadingScreen],
            "Nightmare Train: Act 2", [NightmareTrainAct2LoadingScreen],
            "Nightmare Train: Act 3", [NightmareTrainAct3LoadingScreen]
        )

        for mapName, patterns in loadingScreens {
            try {
                for pattern in patterns {
                    if (ok := ImageSearch(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 " pattern)) {

                        ; If it's Nightmare Train Act 2 or 3, rerun the other detection method
                        if (mapName = "Nightmare Train: Act 2" or mapName = "Nightmare Train: Act 3") {
                            AddToLog("Nightmare Train Act 2 or 3 detected, running secondary detection...")
                            return DetectMapForInfinityCastle()
                        }

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

HandleInfinityCastleEnd(isVictory := true) {
    if (TimeForChallenge()) {
        AddToLog("[Info] Game over, starting challenge")
        return ClickReturnToLobby()
    }

    if (isVictory) {
        AddToLog("[Info] Game over, going to next room")
        ClickNextRoom()
        return RestartStage()
    } else {
        AddToLog("[Info] Game over, returning to lobby")
        return ClickReturnToLobby()
    }
}