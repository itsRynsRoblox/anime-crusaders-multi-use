#Requires AutoHotkey v2.0

StartStoryMode() {
    
    ; Get current map and act
    currentStoryMap := StoryDropdown.Text
    currentStoryAct := StoryActDropdown.Text
        
    ; Execute the movement pattern
    AddToLog("Moving to position for " currentStoryMap)
    StoryMovement()
    
    ; Start stage
    while !(ok := isMenuOpen("Story")) {
        StoryMovement()
    }

    StartStory(currentStoryMap, currentStoryAct)

    if (currentStoryAct != "Infinite") {
        SelectDifficulty(StoryDifficulty.Text)
    }

    FixClick(595, 468) ; click select
    Sleep(300)
    PlayHereOrMatchmake()
    RestartStage()
}

StartStory(map, act) {
    AddToLog("Starting " map " - " act)
    return StartContent(map, act, GetStoryMap, GetStoryAct, { x: 190, y: 185 }, { x: 340, y: 255 })
}

StoryMovement() {
    FixClick(100, 320) ; Click Teleport
    Sleep (1000)
    WalkToStoryRoom()
}

GetStoryMap(map) {
    switch map {
        case "Planet Namak": return {x: 200, y: 250, scrolls: 0}
        case "Marine's Ford": return {x: 200, y: 295, scrolls: 0}
        case "Karakura Town": return {x: 200, y: 340, scrolls: 0}
        case "Shibuya": return {x: 200, y: 385, scrolls: 0}
        case "Demon District": return {x: 200, y: 430, scrolls: 0}
    }
}

GetStoryAct(act) {
    baseX := 340
    baseY := 255
    spacing := 45

    ; Handle "Infinite" at position 0
    if (act = "Infinite") {
        y := baseY
        return { x: baseX, y: baseY, scrolls: 0 }
    }

    ; Handle numbered Acts
    if RegExMatch(act, "Act\s*(\d+)", &match) {
        actNumber := match[1]
        y := baseY + spacing * actNumber  ; Infinite is position 0
        scrolls := (actNumber >= 5) ? 1 : 0
        if (actNumber = 5) {
            y := 330
        }
        else if (actNumber = 6) {
            y := 375
        }
        return { x: baseX, y: y, scrolls: scrolls }
    }

    ; Fallback for invalid input
    return { x: baseX, y: baseY, scrolls: 0 }
}

SelectDifficulty(name := "") {
    switch name {
        case "Normal":
            FixClick(435, 380)
        case "Hard":
            FixClick(485, 380)    
    }
    Sleep(1000)
}

WalkToStoryRoom() {
    Walk("a", 1500)
    Walk("w", 1500)
    Walk("a", 3200)
    Walk("w", 2500)
}

GetNewStorySettings() {

    StoryMapList := ["Planet Namak", "Marine's Ford", "Karakura Town", "Shibuya", "Demon District"]
    map := StoryDropdown.Value
    act := StoryActDropdown.Value

    maxAct := 6  ; Acts 1-6

    ; Convert dropdown act -> internal act 1-6, skipping Infinite at index 1
    if (act = "Infinite")
        act := 1
    else
        act := act - 1  ; dropdown index 2 = Act 1, etc.

    ; If not at final act → increment act
    if (act < maxAct) {
        return {
            mapIndex: StoryDropdown.Value,
            mapName: StoryMapList[StoryDropdown.Value],
            act: act + 1
        }
    }

    ; Finished act 6 → move to next map
    currentMapIndex := StoryDropdown.Value
    totalMaps := StoryMapList.Length

    if (currentMapIndex < totalMaps) {
        nextMapIndex := currentMapIndex + 1
        return {
            mapIndex: nextMapIndex,
            mapName: StoryMapList[nextMapIndex],
            act: 1
        }
    }

    ; Last map finished → stay on last map, Act 6
    return {
        mapIndex: currentMapIndex,
        mapName: StoryMapList[currentMapIndex],
        act: maxAct
    }
}

SetNewStorySettings(settings) {
    global firstStartup

    oldMap := StoryDropdown.Value
    oldMapName := StoryDropdown.Text

    ; Set map by index
    StoryDropdown.Value := settings.mapIndex

    ; Convert act (1–6) → dropdown index 2–7
    StoryActDropdown.Value := (settings.act + 1)

    ; Check if map changed
    if (settings.mapIndex != oldMap) {
        AddToLog("Completed map: " oldMapName ", starting new map: " settings.mapName)
        firstStartup := true
    }
}


TestStoryProgression() {
    AddToLog("Starting Story Progression Test...")

    loop 10 {
        new := GetNewStorySettings()
        SetNewStorySettings(new)
        Sleep 1000
    }
}
