#Requires AutoHotkey v2.0

StartEvent() {
    switch (EventDropdown.Text) {
        case "Halloween":
            StartHalloween()
        case "Gates":
            StartGates()
        case "Spirit Invasion":
            StartSpiritInvasion()
        default: 
            AddToLog("Invalid event selected: " . EventDropdown.Text)
    }
}

HandlePlayHere() {
    switch (EventRoleDropdown.Text) {
        case "Solo":
            FixClick(331, 350)
            Sleep(1500)
            FixClick(410, 525)
        case "Host":
            FixClick(331, 350)
            Sleep(15000)
            FixClick(410, 525)
        case "Guest":
            FixClick(331, 350)
            Sleep(1500)
        default: 
            AddToLog("Invalid role selected: " . EventRoleDropdown.Text)
    }
}

HandleEventMovement() {
    switch (EventDropdown.Text) {
        case "Halloween":
            if (HalloweenMovement.Value) {
                WalkDownPath()
            }
        case "Gates":
            if (GateMovement.Value) {
                WalkToCenterOfGateRoom()
            }
    }
}

HandleEventEnd() {
    if (TimeForChallenge()) {
        AddToLog("[Info] Game over, starting challenge")
        return ClickReturnToLobby()
    }

    if (Matchmaking.Value) {
        AddToLog("[Info] Game over, returning to lobby for matchmaking")
        return ClickReturnToLobby()
    } else {
        AddToLog("[Info] Game over, restarting stage")
        ClickReplay()
        return RestartStage()
    }
}