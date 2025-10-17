#Requires AutoHotkey v2.0

StartRaidMode() {

    ; Get current map and act
    currentRaidMap := RaidDropdown.Text
    currentRaidAct := RaidActDropdown.Text

    ; Start stage
    while !(ok := isMenuOpen("Raids")) {
        RaidMovement()
    }

    AddToLog("Starting " currentRaidMap " - " currentRaidAct)
    StartRaid(currentRaidMap, currentRaidAct)
    FixClick(595, 468) ; click select
    Sleep(300)
    PlayHereOrMatchmake()
    RestartStage()
}

StartRaid(map, act) {
    return StartContent(map, act, GetRaidMap, GetRaidAct, { x: 195, y: 255 }, { x: 340, y: 255 })
}

RaidMovement() {
    Teleport("Raid")
    Sleep(1000)
    WalkToRaidRoom()
    Sleep(1000)
}

WalkToRaidRoom() {
    FixClick(415, 465)
    Walk("a", 2000)
    Walk("w", 2000)
    Walk("a", 2500)
    Walk("w", 6000)
}

GetRaidMap(map) {

    RaidMapNames := [
        "Amusement Park", "Test"
    ]

    baseX := 195
    baseY := 255
    spacing := 45

    for index, name in RaidMapNames {
        if (map = name) {
            x := baseX + spacing * (index - 1)
            scrolls := (index > 4) ? 1 : 0  ; Adjust this threshold as needed
            return { x: x, y: baseY, scrolls: scrolls }
        }
    }

    ; Fallback if map not found
    return { x: baseX, y: baseY, scrolls: 0 }
}

GetRaidAct(act) {
    baseX := 340
    baseY := 255
    spacing := 45

    ; Handle numbered Acts
    if RegExMatch(act, "Act\s*(\d+)", &match) {
        actNumber := match[1]
        y := baseY + spacing * (actNumber - 1)
        scrolls := (actNumber >= 5) ? 1 : 0
        return { x: baseX, y: y, scrolls: scrolls }
    }

    ; Fallback for invalid input
    return { x: baseX, y: baseY, scrolls: 0 }
}