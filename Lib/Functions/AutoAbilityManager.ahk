#Requires AutoHotkey v2.0

CheckAutoAbility() {
    if (!HasUnitForAbilityCheck()) {
        return  ; No units to check
    }

    AddToLog("Checking auto abilities of placed units...")

    global successfulCoordinates, maxedCoordinates

    ; Process successfulCoordinates
    for index, coord in successfulCoordinates {
        if (!coord.hasAbility)
            continue

        if (ProcessAbility(coord)) {
            successfulCoordinates[index].hasAbility := false
        }
    }

    ; Process maxedCoordinates
    for index, coord in maxedCoordinates {
        if (!coord.hasAbility)
            continue

        if (ProcessAbility(coord)) {
            maxedCoordinates[index].hasAbility := false
        }
    }

    AddToLog("Finished looking for abilities")
}

HasUnitForAbilityCheck() {
    global successfulCoordinates, maxedCoordinates

    for coord in successfulCoordinates {
        if (coord.hasAbility)
            return true
    }

    for coord in maxedCoordinates {
        if (coord.hasAbility)
            return true
    }

    return false
}

ProcessAbility(coord) {

    slot := coord.slot

    if (isMenuOpen("End Screen")) {
        AddToLog("Stopping auto ability check because the game ended")
        MonitorStage()
        return false
    }

    if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
        CheckForCardSelection()
    }

    if (NukeUnitSlotEnabled.Value && slot = NukeUnitSlot.Value) {
        return false
    }

    FixClick(coord.x, coord.y)
    Sleep(500)

    if (HandleAutoAbility()) {
        return true
    }

    return false
}

GetAutoAbilityTimer() {
    seconds := AutoAbilityTimer.Value
    return Round(seconds * 1000)
}

ActiveAbilityEnabled() {
    if (autoAbilityDisabled) {
        return false
    }

    if (AutoAbilityBox.Value) {
        return true
    }
    return false
}