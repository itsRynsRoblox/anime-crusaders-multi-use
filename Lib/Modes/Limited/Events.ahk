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