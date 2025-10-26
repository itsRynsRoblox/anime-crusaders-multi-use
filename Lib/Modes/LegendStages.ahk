#Requires AutoHotkey v2.0

StartLegendStages() {

    ; Get current map and act
    currentMap := LegendDropDown.Text
    currentAct := LegendActDropdown.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentMap)
    StoryMovement()

    ; Start stage
    while !(ok := isMenuOpen("Story")) {
        StoryMovement()
    }

    AddToLog("Starting " currentMap " - " currentAct)
    SelectLegendStage()
    StartLegendStage(currentMap, currentAct)

    FixClick(594, 467) ;click select
    Sleep(750)
    ; Handle play mode selection
    PlayHereOrMatchmake()
    RestartStage()
}

SelectLegendStage() {
    FixClick(610, 215)
    Sleep(500)
}

StartLegendStage(map, act) {
    return StartContent(map, act, GetLegendMap, GetLegendAct, { x: 190, y: 185 }, { x: 340, y: 255 })
}

GetLegendMap(map) {

    RaidMapNames := [
        "Shibuya (Destroyed)", "Nightmare Train"
    ]

    baseX := 195
    baseY := 255
    spacing := 45

    for index, name in RaidMapNames {
        if (map = name) {
            y := baseY + spacing * (index - 1)
            scrolls := (index > 4) ? 1 : 0  ; Adjust this threshold as needed
            return { x: baseX, y: y, scrolls: scrolls }
        }
    }

    ; Fallback if map not found
    return { x: baseX, y: baseY, scrolls: 0 }
}

GetLegendAct(act) {
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