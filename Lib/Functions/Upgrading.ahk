#Requires AutoHotkey v2.0

UpgradeUnits() {

    if (ShouldOpenUnitManager()) {
        OpenMenu("Unit Manager")
    }

    if (PriorityUpgrade.Value) {
        UpgradeWithPriority()
    } else {
        UpgradeWithoutPriority()
    }

    return MonitorStage()
}

UpgradeWithPriority() {
    global successfulCoordinates
    AddToLog("Using priority upgrade system")
    slotOrder := [1, 2, 3, 4, 5, 6]
    priorityOrder := [1, 2, 3, 4, 5, 6]

    for priorityNum in priorityOrder {
        for slot in slotOrder {
            if (HasUnitsInSlot(slot, priorityNum, successfulCoordinates)) {
                AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                ProcessUpgrades(slot, priorityNum)
            }
        }
    }

    AddToLog("All units maxed, proceeding to monitor stage")
    if (ActiveAbilityEnabled()) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
    }
    CloseMenu("Unit Manager")
}

UpgradeWithoutPriority() {
    global successfulCoordinates

    slotOrder := [1, 2, 3, 4, 5, 6] ; or however many slots you have

    for slot in slotOrder {
        if (HasUnitsInSlot(slot, "", successfulCoordinates)) {
            ProcessUpgrades(slot, "")
            upgraded := true
        }
    }

    AddToLog("All units maxed, proceeding to monitor stage")
}

SetAutoUpgradeForAllUnits(testAmount := 0) {
    global successfulCoordinates

    ; Use test coordinates if testAmount is provided
    if (testAmount > 0) {
        coordinates := []
        loop testAmount {
            index := A_Index
            coordinates.Push({
                slot: index,
                upgradePriority: (index - 1) // 2 + 1,
                placementIndex: index
            })
        }
        AddToLog("Test mode active: Using " testAmount " test coordinates.")
    } else {
        coordinates := successfulCoordinates.Clone()
    }

    ; Sort by placementIndex (simple bubble sort)
    sorted := coordinates
    loop sorted.Length {
        for i, val in sorted {
            if (i = sorted.Length)
                continue
            if (sorted[i].placementIndex > sorted[i + 1].placementIndex) {
                temp := sorted[i]
                sorted[i] := sorted[i + 1]
                sorted[i + 1] := temp
            }
        }
    }

    ; GUI positioning constants
    baseX := 640
    baseY := 170

    colSpacing := 125
    rowSpacing := 88
    maxCols := 2

    totalCount := sorted.Length
    fullRows := Floor(totalCount / maxCols)
    lastRowUnits := Mod(totalCount, maxCols)

    ; Loop through units in visual order
    for index, unit in sorted {
        slot := unit.slot
        priority := unit.upgradePriority

        ; Calculate click position
        placementIndex := index - 1 ; zero-based
        row := Floor(placementIndex / maxCols)
        colInRow := Mod(placementIndex, maxCols)
        isLastRow := (row = fullRows)

        if (lastRowUnits != 0 && isLastRow) {
            rowStartX := baseX + ((maxCols - lastRowUnits) * colSpacing / 2)
            clickX := rowStartX + (colInRow * colSpacing)
        } else {
            clickX := baseX + (colInRow * colSpacing)
        }

        clickY := baseY + (row * rowSpacing)

        ; Normalize priorities
        if (priority > 4 && priority != 7) {
            priority := 4
        }
        if (priority == 7) {
            priority := 0
        }

        AddToLog("Set slot: " slot " priority to " priority)
        FixClick(clickX, clickY)
        Sleep(150)
    }
}

GetUpgradePriority(slotNum) {
    global
    priorityVar := "upgradePriority" slotNum
    return %priorityVar%.Value
}

UnitManagerUpgradeWithLimit(coord, index, upgradeLimit) {
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(coord.placementIndex)
        Sleep(500)
    }
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
    
}

ProcessUpgrades(slot := false, priorityNum := false) {
    global successfulCoordinates

    ; Full upgrade loop
    while (true) {
        slotDone := true

        for index, coord in successfulCoordinates {

            if (coord.autoUpgrade || coord.upgradePriority = "") {
                continue
            }

            if ((!slot || coord.slot = slot) && (!priorityNum || coord.upgradePriority = priorityNum)) {
                slotDone := false  ; Found unit to upgrade => not done yet

                UpgradeUnitWithLimit(coord, index)

                PostUpgradeChecks(coord)

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                    CloseUnitUI()
                }

                if (!UnitManagerUpgradeSystem.Value) {
                    CloseUnitUI()
                }

                PostUpgradeChecks(coord)
            }
        }

        if ((slot || priorityNum) && (slotDone || successfulCoordinates.Length = 0)) {
            AddToLog("Finished upgrades for priority " priorityNum)
            break
        }

        if (!slot && !priorityNum)
            break
    }
}

WaitForUpgradeText(timeout := 4500) {
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        ; Check for the pixel as usual
        if (ok := GetPixel(0x5C7FBB, 20, 472, 2, 2, 5)) {
            return true
        }

        CloseUnitPassives()

        ; Card selection check
        if (isMenuOpen("Card Selection")) {
            SelectCardsByMode()
            startTime := A_TickCount  ; ← Reset timer if card interrupted the process
        }

        Sleep 100
    }
    return false  ; Timed out
}

WaitForUpgradeLimitText(upgradeCap, timeout := 4500) {
    upgradeTexts := [
        Upgrade0, Upgrade1, Upgrade2, Upgrade3, Upgrade4, Upgrade5, Upgrade6, Upgrade7, Upgrade8, Upgrade9
    ]
    targetText := upgradeTexts[upgradeCap]

    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        if (FindText(&X, &Y, 235, 243, 264, 263, 0, 0, targetText)) {
            AddToLog("Found Upgrade Cap")
            return true
        }

        ; Card selection check
        if (isMenuOpen("Card Selection")) {
            SelectCardsByMode()
            startTime := A_TickCount  ; ← Reset timer if card interrupted the process
        }

        Sleep 100
    }
    return false  ; Timed out
}

UpgradeUnitWithLimit(coord, index) {
    slot := coord.slot
    placementIndex := coord.placementIndex
    x := coord.x
    y := coord.y

    isLimitDisabled := !IsUpgradeLimitEnabled(slot) || unitUpgradeLimitDisabled
    useUnitManager := UnitManagerUpgradeSystem.Value

    if isLimitDisabled {
        if useUnitManager {
            UnitManagerUpgrade(placementIndex)
        } else {
            UpgradeUnit(x, y)
        }
        return
    }

    limit := GetUpgradeLimit(slot)
    if useUnitManager {
        UnitManagerUpgradeWithLimit(coord, index, limit)
    } else {
        UpgradeUnitLimit(coord, index, limit)
    }
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

UpgradeUnitLimit(coord, index, upgradeLimit) {
    FixClick(coord.x, coord.y)
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
}

HandleMaxUpgrade(coord, index) {
    global successfulCoordinates, maxedCoordinates
    AddToLog("Max upgrade reached for Unit: " coord.slot)
    maxedCoordinates.Push(coord)
    successfulCoordinates.RemoveAt(index)
}

PostUpgradeChecks(coord) { 

    if (isMenuOpen("End Screen")) {
        return HandleStageEnd()
    }

    if (coord.hasAbility) {
        HandleAutoAbility()
    }

    if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
        CheckForCardSelection()
    }

    if (isMenuOpen("End Screen")) {
        return HandleStageEnd()
    }

    Reconnect()
}

IsUpgradeLimitEnabled(slotNum) {
    setting := "upgradeLimitEnabled" slotNum
    return %setting%.Value
}

GetUpgradeLimit(slotNum) {
    setting := "upgradeLimit" slotNum
    return %setting%.Text
}

TestAllUpgradeFindTexts() {
    foundCount := 0
    notFoundCount := 0

    Loop 9 {
        upgradeCap := A_Index  ; Now 1–15, aligns with AHK v2 arrays
        result := WaitForUpgradeLimitText(upgradeCap, 500)

        if (result) {
            AddToLog("Found Upgrade Level: " upgradeCap - 1)
            foundCount++
        } else {
            AddToLog("Did NOT Find Upgrade Level: " upgradeCap - 1)
            notFoundCount++
        }
    }

    AddToLog("Found: " foundCount " | Not Found: " notFoundCount)
}

HasUnitsInSlot(slot, priorityNum, coordinates) {
    for coord in coordinates {
        if (coord.slot = slot && !coord.autoUpgrade) {
            if (priorityNum = false || priorityNum = "") {
                return true   ; ignore priority requirement
            }
            if (coord.upgradePriority = priorityNum) {
                return true
            }
        }
    }
    return false
}

ShouldOpenUnitManager() {
    if (UnitManagerUpgradeSystem.Value) {
        return true
    }
}

EnableAutoUpgrade() {
    FixClick(136, 293)
}

MaxUpgrade() {
    Sleep 500
    ok := (
        FindText(&X, &Y, 192, 396, 317, 432, 0.10, 0.10, MaxUpgradeText)
        || FindText(&X, &Y, 192, 396, 317, 432, 0.20, 0.20, MaxUpgradeTextIdol)
    )
    return ok
}

UnitManagerUpgrade(slot) {
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(slot)
        Sleep(500)
    }
    loop 3 {
        SendInput("T")
    }
}