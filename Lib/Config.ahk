#Include %A_ScriptDir%\Lib\GUI.ahk

SaveSettingsForMode(toExport := false) {
    try {
        ; Determine mode name
        gameMode := (ModeConfigurations.Value ? ModeDropdown.Text : "Default")
        if !gameMode
            gameMode := "Default"

        safeMode := RegExReplace(gameMode, '[\\/:*?"<>|]', "_")

        if (toExport) {
            file := A_ScriptDir "\Settings\Export\" safeMode "_Configuration.json"
        } else {
            file := A_ScriptDir "\Settings\Modes\" safeMode "_Configuration.json"
        }

        ; Build JSON data map
        data := {
            Unit_Settings: {
                Slot_1_Enabled: Enabled1.Value, Slot_2_Enabled: Enabled2.Value, Slot_3_Enabled: Enabled3.Value,
                Slot_4_Enabled: Enabled4.Value, Slot_5_Enabled: Enabled5.Value, Slot_6_Enabled : Enabled6.Value,

                Slot_1_Placements: Placement1.Value, Slot_2_Placements: Placement2.Value, Slot_3_Placements: Placement3.Value,
                Slot_4_Placements: Placement4.Value, Slot_5_Placements: Placement5.Value, Slot_6_Placements: Placement6.Value,

                Slot_1_Priority: Priority1.Value, Slot_2_Priority: Priority2.Value, Slot_3_Priority: Priority3.Value,
                Slot_4_Priority: Priority4.Value, Slot_5_Priority: Priority5.Value, Slot_6_Priority: Priority6.Value,

                Slot_1_Upgrade_Priority: UpgradePriority1.Text, Slot_2_Upgrade_Priority: UpgradePriority2.Text, Slot_3_Upgrade_Priority: UpgradePriority3.Text,
                Slot_4_Upgrade_Priority: UpgradePriority4.Text, Slot_5_Upgrade_Priority: UpgradePriority5.Text, Slot_6_Upgrade_Priority: UpgradePriority6.Text,

                Slot_1_Upgrade_Enabled: UpgradeEnabled1.Value, Slot_2_Upgrade_Enabled: UpgradeEnabled2.Value, Slot_3_Upgrade_Enabled: UpgradeEnabled3.Value,
                Slot_4_Upgrade_Enabled: UpgradeEnabled4.Value, Slot_5_Upgrade_Enabled: UpgradeEnabled5.Value, Slot_6_Upgrade_Enabled: UpgradeEnabled6.Value,

                Slot_1_Upgrade_Limit: UpgradeLimit1.Text, Slot_2_Upgrade_Limit: UpgradeLimit2.Text, Slot_3_Upgrade_Limit: UpgradeLimit3.Text,
                Slot_4_Upgrade_Limit: UpgradeLimit4.Text, Slot_5_Upgrade_Limit: UpgradeLimit5.Text, Slot_6_Upgrade_Limit: UpgradeLimit6.Text,

                Slot_1_Upgrade_Limit_Enabled: UpgradeLimitEnabled1.Value, Slot_2_Upgrade_Limit_Enabled: UpgradeLimitEnabled2.Value, Slot_3_Upgrade_Limit_Enabled: UpgradeLimitEnabled3.Value,
                Slot_4_Upgrade_Limit_Enabled: UpgradeLimitEnabled4.Value, Slot_5_Upgrade_Limit_Enabled: UpgradeLimitEnabled5.Value, Slot_6_Upgrade_Limit_Enabled: UpgradeLimitEnabled6.Value
            },
            Auto_Ability: {
                Enabled: AutoAbilityBox.Value,
                Timer: AutoAbilityTimer.Text
            },
            Zoom_Settings: {
                Level: ZoomBox.Value,
                Enabled: ZoomTech.Value,
                Zoom_In: ZoomInOption.Value,
                Teleport: ZoomTeleport.Value
            },
            Upgrading: {
                Enabled: EnableUpgrading.Value,
                Use_Unit_Manager: UnitManagerUpgradeSystem.Value,
                Use_Unit_Priority: PriorityUpgrade.Value
            },
            Custom_Recordings: {
                Use: ShouldUseRecording.Value,
                Loop: ShouldLoopRecording.Value,
                HandleEnd: ShouldHandleGameEnd.Value
            },
            Nuke: {
                Enabled: NukeUnitSlotEnabled.Value,
                Slot: NukeUnitSlot.Value,
                Coords: { X: nukeCoords.x, Y: nukeCoords.y },
                AtSpecificWave: NukeAtSpecificWave.Value,
                Wave: NukeWave.Value,
                Delay: NukeDelay.Value
            },
            Unit_Manager_Fixes: {
                Slot1AddsExtraUnit: MinionSlot1.Value,
                Slot2AddsExtraUnit: MinionSlot2.Value,
                Slot3AddsExtraUnit: MinionSlot3.Value,
                Slot4AddsExtraUnit: MinionSlot4.Value,
                Slot5AddsExtraUnit: MinionSlot5.Value,
                Slot6AddsExtraUnit: MinionSlot6.Value
            },
            Modes: {
                Portals: {
                  Farm_Portals: FarmMorePortals.Value  
                },
                Events: {
                    Halloween: {
                        Use_Premade_Movement: HalloweenMovement.Value
                    },
                    Gates: {
                        Use_Premade_Movement: GateMovement.Value
                    }
                }
            }
        }

        ; Convert to JSON
        json := jsongo.Stringify(data, "", "    ")

        ; Save to file
        if FileExist(file)
            FileDelete(file)
        FileAppend(json, file, "UTF-8")

        if (toExport) {
            AddToLog("✅ Successfully exported settings for mode: " gameMode)
            return
        }

        AddToLog("✅ Saved settings for mode: " gameMode)

        ; Save related components
        SaveCustomPlacements()
        SaveAllMovements()
        SaveAllRecordings()
        SaveUniversalSettings()
        SaveAllConfigs()
    }
    catch {
        AddToLog("Error saving mode settings")
    }
}

LoadUnitSettingsByMode(fromFile := false) {
    global nukeCoords

    mode := ModeDropdown.Text
    if !mode
        mode := "Default"

    safeMode := RegExReplace(mode, '[\\/:*?"<>|]', "_")

    if (fromFile) {
        ; Temporarily disable AlwaysOnTop for file dialog
        MainUI.Opt("-AlwaysOnTop")
        Sleep(100)

        file := FileSelect(3, , "Select a configuration file to import", "JSON Files (*.json)")

        MainUI.Opt("+AlwaysOnTop")

        if !file
            return
    } else {
        file := A_ScriptDir "\Settings\Modes\" safeMode "_Configuration.json"
    }

    if !FileExist(file) {
        AddToLog("⚠️ No configuration found for mode: " mode ", using default settings...")
        SaveSettingsForMode()
        return
    }

    json := FileRead(file, "UTF-8")

    js := jsongo
    js.silent_error := true
    js.extract_objects := true

    data := js.Parse(json)

    if (data = "" || !IsObject(data)) {
        AddToLog("⚠️ Failed to parse JSON, using empty config.")
        data := {} ; fallback object
    }

    Enabled1.Value := data["Unit_Settings"]["Slot_1_Enabled"]
    Enabled2.Value := data["Unit_Settings"]["Slot_2_Enabled"]
    Enabled3.Value := data["Unit_Settings"]["Slot_3_Enabled"]
    Enabled4.Value := data["Unit_Settings"]["Slot_4_Enabled"]
    Enabled5.Value := data["Unit_Settings"]["Slot_5_Enabled"]
    Enabled6.Value := data["Unit_Settings"]["Slot_6_Enabled"]

    Placement1.Value := data["Unit_Settings"]["Slot_1_Placements"]
    Placement2.Value := data["Unit_Settings"]["Slot_2_Placements"]
    Placement3.Value := data["Unit_Settings"]["Slot_3_Placements"]
    Placement4.Value := data["Unit_Settings"]["Slot_4_Placements"]
    Placement5.Value := data["Unit_Settings"]["Slot_5_Placements"]
    Placement6.Value := data["Unit_Settings"]["Slot_6_Placements"]

    Priority1.Value := data["Unit_Settings"]["Slot_1_Priority"]
    Priority2.Value := data["Unit_Settings"]["Slot_2_Priority"]
    Priority3.Value := data["Unit_Settings"]["Slot_3_Priority"]
    Priority4.Value := data["Unit_Settings"]["Slot_4_Priority"]
    Priority5.Value := data["Unit_Settings"]["Slot_5_Priority"]
    Priority6.Value := data["Unit_Settings"]["Slot_6_Priority"]

    UpgradePriority1.Text := data["Unit_Settings"]["Slot_1_Upgrade_Priority"]
    UpgradePriority2.Text := data["Unit_Settings"]["Slot_2_Upgrade_Priority"]
    UpgradePriority3.Text := data["Unit_Settings"]["Slot_3_Upgrade_Priority"]
    UpgradePriority4.Text := data["Unit_Settings"]["Slot_4_Upgrade_Priority"]
    UpgradePriority5.Text := data["Unit_Settings"]["Slot_5_Upgrade_Priority"]
    UpgradePriority6.Text := data["Unit_Settings"]["Slot_6_Upgrade_Priority"]

    UpgradeEnabled1.Value := data["Unit_Settings"]["Slot_1_Upgrade_Enabled"]
    UpgradeEnabled2.Value := data["Unit_Settings"]["Slot_2_Upgrade_Enabled"]
    UpgradeEnabled3.Value := data["Unit_Settings"]["Slot_3_Upgrade_Enabled"]
    UpgradeEnabled4.Value := data["Unit_Settings"]["Slot_4_Upgrade_Enabled"]
    UpgradeEnabled5.Value := data["Unit_Settings"]["Slot_5_Upgrade_Enabled"]
    UpgradeEnabled6.Value := data["Unit_Settings"]["Slot_6_Upgrade_Enabled"]

    UpgradeLimit1.Text := data["Unit_Settings"]["Slot_1_Upgrade_Limit"]
    UpgradeLimit2.Text := data["Unit_Settings"]["Slot_2_Upgrade_Limit"]
    UpgradeLimit3.Text := data["Unit_Settings"]["Slot_3_Upgrade_Limit"]
    UpgradeLimit4.Text := data["Unit_Settings"]["Slot_4_Upgrade_Limit"]
    UpgradeLimit5.Text := data["Unit_Settings"]["Slot_5_Upgrade_Limit"]
    UpgradeLimit6.Text := data["Unit_Settings"]["Slot_6_Upgrade_Limit"]

    UpgradeLimitEnabled1.Value := data["Unit_Settings"]["Slot_1_Upgrade_Limit_Enabled"]
    UpgradeLimitEnabled2.Value := data["Unit_Settings"]["Slot_2_Upgrade_Limit_Enabled"]
    UpgradeLimitEnabled3.Value := data["Unit_Settings"]["Slot_3_Upgrade_Limit_Enabled"]
    UpgradeLimitEnabled4.Value := data["Unit_Settings"]["Slot_4_Upgrade_Limit_Enabled"]
    UpgradeLimitEnabled5.Value := data["Unit_Settings"]["Slot_5_Upgrade_Limit_Enabled"]
    UpgradeLimitEnabled6.Value := data["Unit_Settings"]["Slot_6_Upgrade_Limit_Enabled"]

    AutoAbilityBox.Value := data["Auto_Ability"]["Enabled"]
    AutoAbilityTimer.Text := data["Auto_Ability"]["Timer"]

    ZoomBox.Value := data["Zoom_Settings"]["Level"]
    ZoomTech.Value := data["Zoom_Settings"]["Enabled"]
    ZoomInOption.Value := data["Zoom_Settings"]["Zoom_In"]
    ZoomTeleport.Value := data["Zoom_Settings"]["Teleport"]

    EnableUpgrading.Value := data["Upgrading"]["Enabled"]
    UnitManagerUpgradeSystem.Value := data["Upgrading"]["Use_Unit_Manager"]
    PriorityUpgrade.Value := data["Upgrading"]["Use_Unit_Priority"]

    ShouldUseRecording.Value := data["Custom_Recordings"]["Use"]
    ShouldLoopRecording.Value := data["Custom_Recordings"]["Loop"]
    ShouldHandleGameEnd.Value := data["Custom_Recordings"]["HandleEnd"]

    NukeUnitSlotEnabled.Value := data["Nuke"]["Enabled"]
    NukeUnitSlot.Value := data["Nuke"]["Slot"]
    nukeCoords := { x: data["Nuke"]["Coords"]["X"], y: data["Nuke"]["Coords"]["Y"] }
    NukeAtSpecificWave.Value := data["Nuke"]["AtSpecificWave"]
    NukeWave.Value := data["Nuke"]["Wave"]
    NukeDelay.Value := data["Nuke"]["Delay"]

    MinionSlot1.Value := data["Unit_Manager_Fixes"]["Slot1AddsExtraUnit"]
    MinionSlot2.Value := data["Unit_Manager_Fixes"]["Slot2AddsExtraUnit"]
    MinionSlot3.Value := data["Unit_Manager_Fixes"]["Slot3AddsExtraUnit"]
    MinionSlot4.Value := data["Unit_Manager_Fixes"]["Slot4AddsExtraUnit"]
    MinionSlot5.Value := data["Unit_Manager_Fixes"]["Slot5AddsExtraUnit"]
    MinionSlot6.Value := data["Unit_Manager_Fixes"]["Slot6AddsExtraUnit"]

    FarmMorePortals.Value := GetNestedValue(data, ["Modes", "Portals", "Farm_Portals"], 0)
    HalloweenMovement.Value := GetNestedValue(data, ["Modes", "Events", "Halloween", "Use_Premade_Movement"], 0)
    GateMovement.Value := GetNestedValue(data, ["Modes", "Events", "Gates", "Use_Premade_Movement"], 0)


    LoadCustomPlacements()
    InitControlGroups()
    LoadUniversalSettings()
    LoadAllMovements()
    LoadAllRecordings()
    LoadAllCardConfig()
    LoadAllProfiles()

    AddToLog("✅ Settings successfully loaded for mode: " mode)
}

LoadUniversalSettings() {
    file := A_ScriptDir "\Settings\Modes\Universal_Configuration.json"

    if !FileExist(file) {
        AddToLog("⚠️ No universal settings file found. Creating default JSON...")
        SaveUniversalSettings()
        return
    }

    json := FileRead(file, "UTF-8")
    data := jsongo.Parse(json)

    NextLevelBox.Value := data["Universal"]["NextLevel"]
    ReturnLobbyBox.Value := data["Universal"]["ReturnToLobby"]
    ModeConfigurations.Value := data["Universal"]["UsingModeConfigurations"]

    WebhookEnabled.Value := data["Webhook"]["Enabled"]
    WebhookURLBox.Text := data["Webhook"]["URL"]
    WebhookLogsEnabled.Value := data["Webhook"]["LogsEnabled"]

    PrivateServerEnabled.Value := data["PrivateServer"]["Enabled"]
    PrivateServerURLBox.Text := data["PrivateServer"]["URL"]

    Matchmaking.Value := data["Matchmaking"]["Enabled"]
    MatchmakingFailsafe.Value := data["Matchmaking"]["Failsafe"]
    MatchmakingFailsafeTimer.Value := data["Matchmaking"]["FailsafeTimer"]

    StoryDifficulty.Value := data["Story"]["Difficulty"]

    PlacementPatternDropdown.Value := data["Placement"]["Pattern"]
    PlacementSelection.Value := data["Placement"]["Order"]
    PlaceSpeed.Value := data["Placement"]["Speed"]
    PlaceUntilSuccessful.Value := data["Placement"]["PlaceUntilSuccessful"]
}

SaveUniversalSettings() {
    data := {
        Universal: {
            NextLevel: NextLevelBox.Value,
            ReturnToLobby: ReturnLobbyBox.Value,
            UsingModeConfigurations: ModeConfigurations.Value
        },
        Webhook: {
            Enabled: WebhookEnabled.Value,
            URL: WebhookURLBox.Text,
            LogsEnabled: WebhookLogsEnabled.Value
        },
        PrivateServer: {
            Enabled: PrivateServerEnabled.Value,
            URL: PrivateServerURLBox.Text
        },
        Matchmaking: {
            Enabled: Matchmaking.Value,
            Failsafe: MatchmakingFailsafe.Value,
            FailsafeTimer: MatchmakingFailsafeTimer.Value
        },
        Story: {
            Difficulty: StoryDifficulty.Value
        },
        Placement: {
            Pattern: PlacementPatternDropdown.Value,
            Order: PlacementSelection.Value,
            Speed: PlaceSpeed.Value,
            PlaceUntilSuccessful: PlaceUntilSuccessful.Value
        }
    }

    file := A_ScriptDir "\Settings\Modes\Universal_Configuration.json"
    json := jsongo.Stringify(data, "", "    ")

    if FileExist(file)
        FileDelete(file)

    FileAppend(json, file, "UTF-8")
}

ExportCoordinatesPreset(presetIndex) {
    global savedCoords

    if !IsSet(savedCoords) || savedCoords.Length < presetIndex || savedCoords[presetIndex].Length = 0 {
        AddToLog("⚠️ No coordinates saved for Preset " presetIndex)
        return
    }

    ; Ensure export directory
    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    file := exportDir "\Preset" presetIndex ".txt"

    exportData := Format("[Preset {1}]`n", presetIndex)
    for coord in savedCoords[presetIndex] {
        exportData .= Format("X={1}, Y={2}`n", coord.x, coord.y)
    }

    try {
        if FileExist(file)
            FileDelete(file)
        FileAppend(exportData, file)
    } catch {
        AddToLog "❌ Failed to save preset"
        return
    }

    AddToLog("✅ Preset " presetIndex " exported to: Settings\Export\Preset" presetIndex ".txt")
}

ImportCoordinatesPreset() {
    global savedCoords, MainUI

    ; Allow file dialog to appear
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    file := FileSelect(3, , "Import a custom placement preset", "Text Documents (*.txt)")

    if !file
        return

    content := FileRead(file)
    lines := StrSplit(content, "`n")

    newPresetCoords := []

    for line in lines {
        line := Trim(line)
        if (line = "" || InStr(line, "[Preset"))
            continue

        if (line = "NoCoordinatesSaved") {
            break
        }

        coordParts := StrSplit(line, ", ")
        if coordParts.Length < 2
            continue

        x := StrReplace(coordParts[1], "X=")
        y := StrReplace(coordParts[2], "Y=")
        newPresetCoords.Push({ x: x + 0, y: y + 0 })  ; Convert to numbers
    }

    if newPresetCoords.Length = 0 {
        MsgBox "❌ No coordinates found in file."
        return
    }

    ; Prompt user for target slot using AHK v2 InputBox
    result := InputBox("Enter preset slot (1–10) to import into:", "Import Custom Placements", "h95 w250")

    MainUI.Opt("+AlwaysOnTop")

    if result.Result = "Cancel" {
        AddToLog("❌ Import canceled.")
        return
    }

    targetSlot := Trim(result.Value)

    if !RegExMatch(targetSlot, "^\d+$") || targetSlot < 1 || targetSlot > 10 {
        MsgBox "❌ Invalid input. Please enter a number between 1 and 10."
        return
    }

    targetSlot := targetSlot + 0

    ; Ensure array is large enough
    while (savedCoords.Length < targetSlot)
        savedCoords.Push([])

    savedCoords[targetSlot] := newPresetCoords

    AddToLog("✅ Imported preset into slot " targetSlot "!")
}

SaveKeybindSettings(*) {
    AddToLog("Saving Keybind Configuration")
    
    if FileExist("Settings\Keybinds.txt")
        FileDelete("Settings\Keybinds.txt")
        
    FileAppend(Format("F1={}`nF2={}`nF3={}`nF4={}", F1Box.Value, F2Box.Value, F3Box.Value, F4Box.Value), "Settings\Keybinds.txt", "UTF-8")
    
    ; Update globals
    global F1Key := F1Box.Value
    global F2Key := F2Box.Value
    global F3Key := F3Box.Value
    global F4Key := F4Box.Value
    
    ; Update hotkeys
    Hotkey(F1Key, (*) => moveRobloxWindow())
    Hotkey(F2Key, (*) => StartMacro())
    Hotkey(F3Key, (*) => Reload())
    Hotkey(F4Key, (*) => TogglePause())
}

LoadKeybindSettings() {
    if FileExist("Settings\Keybinds.txt") {
        fileContent := FileRead("Settings\Keybinds.txt", "UTF-8")
        Loop Parse, fileContent, "`n" {
            parts := StrSplit(A_LoopField, "=")
            if (parts[1] = "F1")
                global F1Key := parts[2]
            else if (parts[1] = "F2")
                global F2Key := parts[2]
            else if (parts[1] = "F3")
                global F3Key := parts[2]
            else if (parts[1] = "F4")
                global F4Key := parts[2]
        }
    }
}

HasKey(obj, key) {
    return (obj is Map) ? obj.Has(key) : obj.HasOwnProp(key)
}

GetSection(obj, key) {
    return (IsObject(obj) && HasKey(obj, key)) ? obj[key] : {}
}

GetValue(obj, key, fallback := "") {
    return (IsObject(obj) && HasKey(obj, key)) ? obj[key] : fallback
}

; Traverse nested objects safely and return a value or fallback
GetNestedValue(obj, keys, fallback := "") {
    current := obj
    for key in keys {
        if !(IsObject(current) && current.Has(key))
            return fallback
        current := current[key]
    }
    return current
}