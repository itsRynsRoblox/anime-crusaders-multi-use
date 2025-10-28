#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%/lib/Tools/Image.ahk
#Include %A_ScriptDir%/lib/Functions/Functions.ahk

; Application Info
global GameName := "Anime Crusaders"
global GameTitle := "Ryn's " GameName " Macro "
global version := "v1.7.9"
global rblxID := "ahk_exe RobloxPlayerBeta.exe"
; Update Checker
global repoOwner := "itsRynsRoblox"
global repoName := "anime-crusaders-multi-use"
;Coordinate and Positioning Variables
global targetWidth := 816
global targetHeight := 638
global offsetX := -5
global offsetY := 1
global centerX := 408
global centerY := 320
global successfulCoordinates := []
global totalUnits := Map()
;Statistics Tracking
global StartTime := A_TickCount
global currentTime := GetCurrentTime()
; Config and Settings
global UnitConfigMap := Map()
;Auto Challenge
global challengeStartTime := A_TickCount
global inChallengeMode := false
global firstStartup := true
; Testing
global waitingState := Map()
;Custom Unit Placement
global waitingForClick := false
global savedCoords := Map()
; Custom Walk
global savedWalkCoords := Map()
global recording := false
global allWalks := Map()
global keyDownTimes := Map()
global lastActionTime := 0
;Nuke Ability
global nukeCoords := []
;Hotkeys
global F1Key := "F1"
global F2Key := "F2"
global F3Key := "F3"
global F4Key := "F4"
;Gui creation
global uiBorders := []
global uiBackgrounds := []
global uiTheme := []
global UnitData := []
global MainUI := Gui("+AlwaysOnTop -Caption")
global CardGUI := Gui("+AlwaysOnTop")
global lastlog := ""
global MainUIHwnd := MainUI.Hwnd
global ActiveControlGroup := ""
global ControlGroups := Map()
;Theme colors
uiTheme.Push("0xffffff")  ; Header color
uiTheme.Push("0c000a")  ; Background color
uiTheme.Push("0xffffff")    ; Border color
uiTheme.Push("0c000a")  ; Accent color
uiTheme.Push("0x3d3c36")   ; Trans color
uiTheme.Push("000000")    ; Textbox color
uiTheme.Push("00a2ff") ; HighLight
;Logs/Save settings
global currentOutputFile := A_ScriptDir "\Logs\LogFile.txt"
;Custom Pictures
GithubImage := "Images\github-logo.png"
DiscordImage := "Images\another_discord.png"

if !DirExist(A_ScriptDir "\Logs") {
    DirCreate(A_ScriptDir "\Logs")
}
if !DirExist(A_ScriptDir "\Settings") {
    DirCreate(A_ScriptDir "\Settings")
}

setupOutputFile()

; === Need To Load These Before GUI ===
global currentCardMode := "Spirit Invasion"
global CardModeConfigs := Map(
    "Spirit Invasion", Map(
        "modeName", "SpiritInvasion",
        "title", "Spirit Invasion Card Priority",
        "filePath", "Settings\SpiritInvasionCardPriority.txt",
        "options", [
            "Tier3BuffCard",
            "Tier2BuffCard",
            "Tier1BuffCard",
            "Tier1TradeOff",
            "Tier2TradeOff",
            "Tier3TradeOff"
        ]
    ),
    "Halloween", Map(
        "modeName", "Halloween",
        "title", "Halloween Card Priority",
        "filePath", "Settings\HalloweenCardPriority.txt",
        "options", [
            "Tier3BuffCard",
            "Tier2BuffCard",
            "Tier1BuffCard",
            "Tier1TradeOff",
            "Tier2TradeOff",
            "Tier3TradeOff"
        ]
    )
)

global currentConfig := CardModeConfigs[currentCardMode]

; ========== Constants and Theme Setup ==========
mainWidth := 1364
mainHeight := 697
robloxWidth := 802
uiColors := Map(
    "Primary", uiTheme[1],
    "Background", uiTheme[2],
    "Border", uiTheme[3],
    "RobloxBox", uiTheme[5],
    "ProcessHighlight", uiTheme[7]
)

; ========== Helper Functions ==========
AddUI(type, options, text := "", onClickFunc := unset) {
    ctrl := MainUI.Add(type, options, text)
    if IsSet(onClickFunc)
        ctrl.OnEvent("Click", onClickFunc)
    return ctrl
}

AddBorder(x, y, w, h) {
    return MainUI.Add("Text", Format("x{} y{} w{} h{} +Background{}", x, y, w, h, uiColors["Border"]))
}
; ========== GUI Initialization ==========

MainUI.BackColor := uiColors["Background"]
global Webhookdiverter := AddUI("Edit", "x0 y0 w1 h1 +Hidden")

; ========== Borders ==========
uiBorders.Push(AddBorder(0, 0, mainWidth, 1))                          ; Top
uiBorders.Push(AddBorder(0, 0, 1, mainHeight))                         ; Left
uiBorders.Push(AddBorder(mainWidth - 1, 0, 1, 630))                    ; Right
uiBorders.Push(AddBorder(mainWidth - 1, 0, 1, mainHeight))            ; Full Right
uiBorders.Push(AddBorder(0, 30, mainWidth - 1, 1))                     ; Under Title
uiBorders.Push(AddBorder(803, 443, 560, 1))                            ; Placement Bottom
uiBorders.Push(AddBorder(803, 527, 560, 1))                            ; Process Bottom
uiBorders.Push(AddBorder(802, 30, 1, 667))                             ; Roblox Right
uiBorders.Push(AddBorder(0, mainHeight - 1, mainWidth, 1))            ; Bottom Line
uiBorders.Push(AddBorder(0, 630, robloxWidth + 0.5, 1))               ; Game Bottom

; ========== Backgrounds ==========
uiBackgrounds.Push(MainUI.Add("Text", Format("x3 y3 w{} h27 +Background{}", mainWidth - 4, uiColors["Background"])))

; ========== Roblox Window Area ==========
global robloxHolder := MainUI.Add("Text", Format("x3 y33 w797 h597 +Background{}", uiColors["RobloxBox"]), "")

; ========== Exit and Minimize Buttons ==========
global exitButton := AddUI("Picture", "x1330 y1 w32 h32 +BackgroundTrans", Exitbutton, (*) => Destroy())
global minimizeButton := AddUI("Picture", "x1305 y3 w27 h27 +Background" uiColors["Background"], Minimize, (*) => minimizeUI())

; ========== Import ==========
global importUnitConfigButton := AddUI("Picture", "x1312 y48 w20 h20 +BackgroundTrans", Import, (*) => ImportSettingsFromFile())
global exportUnitConfigButton := AddUI("Picture", "x1337 y48 w20 h20 +BackgroundTrans", Export, (*) => ExportUnitConfig())

; ========== Title ==========
MainUI.SetFont("Bold s16 c" uiColors["Primary"], "Verdana")
global windowTitle := MainUI.Add("Text", "x10 y3 w1200 h29 +BackgroundTrans", GameTitle "" . "" version)

; ========== Console Label ==========
MainUI.Add("Text", "x805 y501 w558 h25 +Center +BackgroundTrans", "Console")
uiBorders.Push(AddBorder(803, 499, 560, 1)) ; Console Top Border

; ========== Process Text Lines ==========
MainUI.SetFont("norm s11 c" uiColors["Primary"])
global processList := []
baseY := 536

loop 7 {
    yOffset := (A_Index - 1) * 22
    text := ""
    color := uiColors["Primary"]
    if A_Index = 1 {
        text := "➤ Original Creator: Ryn (@TheRealTension)"
        color := uiColors["ProcessHighlight"]
    }
    process := MainUI.Add("Text", Format("x810 y{} w600 h18 +BackgroundTrans c{}", baseY + yOffset, color), text)
    processList.Push(process)
}

; ========== Transparency ==========
WinSetTransColor(uiColors["RobloxBox"], MainUI)

OpenGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop")
    GuideGUI.SetFont("s10 bold", "Segoe UI")
    GuideGUI.Title := "Ryn's " GameName " Guide"

    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Add Guide content
    GuideGUI.SetFont("s16 bold", "Segoe UI")
    GuideGUI.Add("Picture", " cWhite +Center", "Images\settings-1.png")
    GuideGUI.Add("Picture", " cWhite +Center", "Images\settings-2.png")
    GuideGUI.Add("Picture", " cWhite +Center", "Images\settings-3.png")
    GuideGUI.Show("Center")
}

OpenPrivateServerGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop +Resize", "Ryn's Private Server Guide")
    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Reset font for steps
    GuideGUI.SetFont("s12 bold", "Segoe UI")

    ; Add each step individually
    GuideGUI.Add("Text", "cWhite", "Step 1. Create a private server")
    GuideGUI.Add("Text", "cWhite", "Step 2. Name the server however you like")
    GuideGUI.Add("Text", "cWhite", "Step 3. Configure the private server")
    GuideGUI.Add("Text", "cWhite", "Step 4. Generate a link for the server")
    GuideGUI.Add("Text", "cWhite", "Step 5. Paste the link into your browser")
    GuideGUI.Add("Text", "cWhite", "Step 6. Wait for the link to change into the new version")
    GuideGUI.Add("Text", "cWhite", "Step 7. Copy the URL")
    GuideGUI.Add("Text", "cWhite", "Step 8. Paste the URL into the private server section of the macro")
    GuideGUI.Add("Text", "cWhite", "It should look like this at the end: privateServerLinkCode=12345")

    ; Show GUI
    GuideGUI.Show("AutoSize Center")
}

MainUI.SetFont("s9 Bold c" uiTheme[1])

ActiveConfigurationText:= MainUI.Add("Text", "x840 y7 +Center c" uiTheme[1], "Active Configuration: ")
ConfigurationDropdown := MainUI.Add("DropDownList", "x990 y4.5 w110 h180 +Center Choose1", ["Unit", "Challenge", "Cards", "Map Movement", "Mode", "Nuke", "Upgrade"])
ConfigurationDropdown.OnEvent("Change", UpdateActiveConfiguration)

global guideBtn := MainUI.Add("Button", "x1108 y5 w90 h20", "Guide")
guideBtn.OnEvent("Click", OpenGuide)

global cardButton := MainUI.Add("Button", "x808 y5 w90 h20 Hidden", "Card Config")
cardButton.OnEvent("Click", (*) => OpenCardConfig())

global unitButton := MainUI.Add("Button", "x908 y5 w90 h20 Hidden", "Unit Config")
unitButton.OnEvent("Click", (*) => ToggleControlGroup("Unit"))

global upgradeButton := MainUI.Add("Button", "x1008 y5 w90 h20 Hidden", "Upgrades")
upgradeButton.OnEvent("Click", (*) => ToggleControlGroup("Upgrade"))

global modeButton := MainUI.Add("Button", "x1108 y5 w90 h20 Hidden", "Mode Config")
modeButton.OnEvent("Click", (*) => ToggleControlGroup("Mode"))

global settingsBtn := MainUI.Add("Button", "x1208 y5 w90 h20", "Settings")
settingsBtn.OnEvent("Click", (*) => ToggleControlGroup("Settings"))

placementSaveBtn := MainUI.Add("Button", "x807 y471 w80 h20", "Save")
placementSaveBtn.OnEvent("Click", SaveSettingsForMode)

MainUI.SetFont("s9")

global NextLevelBox := MainUI.Add("Checkbox", "x900 y451 cffffff", "Next Level")
global AutoChallenge := MainUI.Add("Checkbox", "x900 y476 cffffff", "Auto Challenge")
global Matchmaking := MainUI.Add("Checkbox", "x1030 y476 cffffff", "Matchmaking")
global PlaceUntilSuccessful := MainUI.Add("CheckBox", "x1145 y476 cffffff", "Place until successful")

global ReturnLobbyBox := MainUI.Add("Checkbox", "x1150 y476 cffffff Checked", "Return To Lobby")

global AutoAbilityBox := MainUI.Add("CheckBox", "x1005 y451 cffffff Checked " (autoAbilityDisabled ? "Hidden" : ""), "Auto Ability")
global AutoAbilityText := MainUI.Add("Text", "x1105 y451 " (autoAbilityDisabled ? " Hidden " : "") " c" uiTheme[1], "| Auto Ability Timer:")
global AutoAbilityTimer := MainUI.Add("Edit", "x1245 y449 w60 h20 " (autoAbilityDisabled ? "Hidden" : "") " cBlack Number", "60")

PlacementPatternText := MainUI.Add("Text", "x815 y390 w125 h20", "Placement Pattern")
global PlacementPatternDropdown := MainUI.Add("DropDownList", "x825 y410 w100 h180 Choose2 +Center", ["Circle", "Custom", "Grid", "3x3 Grid", "Spiral", "Up and Down", "Random"])

PlaceSpeedText := MainUI.Add("Text", "x1025 y390 w115 h20", "Placement Speed")
global PlaceSpeed := MainUI.Add("Edit", "x1055 y410 w60 h20 cBlack Number", "2")

PlacementSelectionText := MainUI.Add("Text", "x1240 y390 w115 h20", "Placement Order")
global PlacementSelection := MainUI.Add("DropDownList", "x1245 y410 w100 h180 Choose1 +Center", ["Default", "By Priority"])

placementSaveText := MainUI.Add("Text", "x807 y451 w80 h20", "Save Config")
Hotkeytext := MainUI.Add("Text", "x807 y35 w200 h30", F1Key ": Fix Roblox Position")
Hotkeytext2 := MainUI.Add("Text", "x807 y50 w200 h30", F2Key ": Start Macro")
Hotkeytext3 := MainUI.Add("Text", "x807 y65 w200 h20", F3Key ": Stop Macro")
GithubButton := MainUI.Add("Picture", "x30 y640", GithubImage)
DiscordButton := MainUI.Add("Picture", "x112 y645 w60 h34 +BackgroundTrans cffffff", DiscordImage)
; === Settings GUI ===
global WebhookBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Webhook Settings")
global WebhookEnabled := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Webhook Enabled")
WebhookEnabled.OnEvent("Click", (*) => ValidateWebhook())
global WebhookLogsEnabled := MainUI.Add("CheckBox", "x825 y130 Hidden cffffff", "Send Console Logs")
global WebhookURLBox := MainUI.Add("Edit", "x1000 y108 w260 h20 Hidden c" uiTheme[6], "")

global PrivateSettingsBorder := MainUI.Add("GroupBox", "x808 y145 w550 h296 +Center Hidden c" uiTheme[1], "Reconnection Settings")
global PrivateServerEnabled := MainUI.Add("CheckBox", "x825 y165 Hidden cffffff", "Reconnect to Private Server")
global PrivateServerURLBox := MainUI.Add("Edit", "x1050 y163 w160 h20 Hidden c" uiTheme[6], "")
PrivateServerTestButton := MainUI.Add("Button", "x1225 y163 w50 h20 Hidden", "Test")
PrivateServerTestButton.OnEvent("Click", (*) => Reconnect(true))
PrivateServerGuideButton := MainUI.Add("Button", "x1285 y163 w50 h20 Hidden", "Guide")
PrivateServerGuideButton.OnEvent("Click", OpenPrivateServerGuide)
global MatchmakingFailsafe := MainUI.Add("CheckBox", "x825 y185 Hidden cffffff", "Enable Matchmaking Failsafe")
global MatchmakingFailsafeTimerText := MainUI.Add("Text", "x1050 y188 h20 Hidden c" uiTheme[1], "Time until reconnect:")
global MatchmakingFailsafeTimer := MainUI.Add("Edit", "x1195 y186 w50 h20 Hidden Number c" uiTheme[6], "60")
; === End of Settings GUI ===

; HotKeys
global KeybindBorder := MainUI.Add("GroupBox", "x808 y205 w195 h176 +Center Hidden c" uiTheme[1], "Keybind Settings")
global F1Text := MainUI.Add("Text", "x825 y230 Hidden c" uiTheme[1], "Position Roblox:")
global F1Box := MainUI.Add("Edit", "x950 y228 w30 h20 Hidden c" uiTheme[6], F1Key)
global F2Text := MainUI.Add("Text", "x825 y260 Hidden c" uiTheme[1], "Start Macro:")
global F2Box := MainUI.Add("Edit", "x950 y258 w30 h20 Hidden c" uiTheme[6], F2Key)
global F3Text := MainUI.Add("Text", "x825 y290 Hidden c" uiTheme[1], "Stop Macro:")
global F3Box := MainUI.Add("Edit", "x950 y288 w30 h20 Hidden c" uiTheme[6], F3Key)
global F4Text := MainUI.Add("Text", "x825 y320 Hidden c" uiTheme[1], "Pause Macro:")
global F4Box := MainUI.Add("Edit", "x950 y318 w30 h20 Hidden c" uiTheme[6], F4Key)

keybindSaveBtn := MainUI.Add("Button", "x880 y350 w50 h20 Hidden", "Save")
keybindSaveBtn.OnEvent("Click", SaveKeybindSettings)

global UpgradeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Upgrade Settings")
global UnitManagerUpgradeSystem := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Use the Unit Manager to upgrade your units")
global PriorityUpgrade := MainUI.Add("CheckBox", "x825 y130 cffffff Hidden", "Use Unit Priority while upgrading")

global ZoomSettingsBorder := MainUI.Add("GroupBox", "x1000 y205 w165 h176 +Center Hidden c" uiTheme[1], "Zoom Tech Settings")
global ZoomText := MainUI.Add("Text", "x1018 y230 Hidden c" uiTheme[1], "Zoom Level:")
global ZoomBox := MainUI.Add("Edit", "x1115 y228 w30 h20 Hidden cBlack Number", "20")
global ZoomTech := MainUI.Add("Checkbox", "x1018 y260 Hidden Checked c" uiTheme[1], "Enable Zoom Tech")
global ZoomInOption := MainUI.Add("Checkbox", "x1018 y290 Hidden Checked c" uiTheme[1], "Zoom in then out")
global ZoomTeleport := MainUI.Add("Checkbox", "x1018 y320 Hidden Checked c" uiTheme[1], "Teleport to spawn")
ZoomBox.OnEvent("Change", (*) => ValidateEditBox(ZoomBox))

global MiscSettingsBorder := MainUI.Add("GroupBox", "x1163 y205 w195 h176 +Center Hidden c" uiTheme[1], "Update Settings")
global UpdateChecker := MainUI.Add("Checkbox", "x1175 y230 Hidden cffffff", "Enable update checker")

global ModeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Mode Configuration")
global ModeConfigurations := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Enable Per-Mode Unit Settings")

; === Normal Modes ===
global StoryBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Story Settings")
global StoryDifficultyText := MainUI.Add("Text", "x825 y110 Hidden", "Story Difficulty:")
global StoryDifficulty := MainUI.Add("DropDownList", "x935 y108 w100 h180 Hidden Choose1 +Center", ["Normal", "Hard"])
global PortalBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Portal Settings")
global FarmMorePortals := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Farm more portals when possible if out of portals")
global ChallengeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Auto Challenge Settings")
global ChallengeTeamSwap := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Swap Teams for Auto Challenge")
global ChallengeTeamText := MainUI.Add("Text", "x825 y140 Hidden", "Challenge Team:")
global ChallengeTeam := MainUI.Add("DropDownList", "x940 y138 w60 h180 Hidden Choose1 +Center", ["1", "2", "3", "4", "5"])
global NormalTeamText := MainUI.Add("Text", "x825 y170 Hidden", "Default Team:")
global NormalTeam := MainUI.Add("DropDownList", "x940 y168 w60 h180 Hidden Choose1 +Center", ["1", "2", "3", "4", "5"])

; === Limited Time Modes ===
global EventBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Event Configuration")
global GateMovement := MainUI.Add("CheckBox", "x825 y250 Hidden cffffff", "[Gates] Use pre-configured movement")
global HalloweenMovement := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "[Halloween] Use pre-configured movement")

; === Card Config GUI ===
global CardBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Card Priority")
global SpiritInvasionCardText := MainUI.Add("Text", "x825 y110 Hidden cffffff", "Spirit Invasion Cards: ")
global SpiritInvasionCardButton := MainUI.Add("Button", "x975 y108 w80 h20 Hidden cffffff", "Edit Cards")
SpiritInvasionCardButton.OnEvent("Click", (*) => SwitchCardMode("Spirit Invasion"))
global HalloweenCardText := MainUI.Add("Text", "x825 y140 Hidden cffffff", "Halloween Cards: ")
global HalloweenCardButton := MainUI.Add("Button", "x975 y138 w80 h20 Hidden cffffff", "Edit Cards")
HalloweenCardButton.OnEvent("Click", (*) => SwitchCardMode("Halloween"))

; === Nuke Config GUI ===
global NukeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden" uiTheme[1], "Nuke Configuration")
global NukeUnitSlotEnabled := MainUI.Add("Checkbox", "x825 y113 Hidden Choose1 cffffff Checked", "Nuke Unit | Slot")
global NukeUnitSlot := MainUI.Add("DropDownList", "x960 y110 w100 h180 Hidden Choose1", ["1", "2", "3", "4", "5", "6"])
global NukeCoordinatesText := MainUI.Add("Text", "x1080 y113 Hidden cffffff", "Nuke Ability Coordinates")
global NukeCoordinatesButton := MainUI.Add("Button", "x1260 y110 w80 h20 Hidden", "Set")
NukeCoordinatesButton.OnEvent("Click", (*) => StartNukeCapture())
global NukeAtSpecificWave := MainUI.Add("Checkbox", "x825 y140 Hidden Choose1 cffffff Checked", "Nuke At Wave | Wave")
global NukeWave := MainUI.Add("DropDownList", "x1000 y137 w100 h180 Hidden Choose1", ["15", "20", "50"])
global NukeDelayText := MainUI.Add("Text", "x1120 y140 Hidden cffffff", "Nuke Delay")
global NukeDelay := MainUI.Add("Edit", "x1210 y138 w40 h20 Hidden cBlack Number", "0")
NukeDelay.OnEvent("Change", (*) => ValidateEditBox(NukeDelay))

global UnitBorder := MainUI.Add("GroupBox", "x808 y161 w550 h220 +Center Hidden" uiTheme[1], "Unit Configuration")
global MinionSlot1 := MainUI.Add("CheckBox", "x825 y181 cffffff Hidden", "Slot 1 has minion")
global MinionSlot2 := MainUI.Add("CheckBox", "x1015 y181 cffffff Hidden", "Slot 2 has minion")
global MinionSlot3 := MainUI.Add("CheckBox", "x1200 y181 cffffff Hidden", "Slot 3 has minion")
global MinionSlot4 := MainUI.Add("CheckBox", "x825 y206 cffffff Hidden", "Slot 4 has minion")
global MinionSlot5 := MainUI.Add("CheckBox", "x1015 y206 cffffff Hidden", "Slot 5 has minion")
global MinionSlot6 := MainUI.Add("CheckBox", "x1200 y206 cffffff Hidden", "Slot 6 has minion")

global PlacementBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden" uiTheme[1], "Placement Configuration")
; === End Unit Config GUI ===

;=== Custom Walk GUI ===
global CustomWalkBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden" uiTheme[1], "Custom Walk Configuration")
global WalkMapText := MainUI.Add("Text", "x875 y110 Hidden cffffff", "Map:")
global WalkMapDropdown := MainUI.Add("DropDownList", "x915 y108 w200 h180 Choose1 +Center Hidden", [
    "Custom",
    ; Story Maps
    "Planet Namak",
    "Marine's Ford",
    "Karakura Town",
    "Shibuya",
    "Demon District",
    ; Legend Stages
    "Shibuya (Destroyed)",
    "Nightmare Train - Act 1",
    "Nightmare Train - Act 2",
    "Nightmare Train - Act 3",
    ; Events
    "Halloween",
    "Spirit Invasion"
])
MovementSetButton := MainUI.Add("Button", "x1130 y110 w60 h20 Hidden", "Set")
MovementSetButton.OnEvent("Click", StartRecordingWalk)
MovementClearButton := MainUI.Add("Button", "x1205 y110 w60 h20 Hidden", "Clear")
MovementClearButton.OnEvent("Click", ClearMovement)
MovementTestButton := MainUI.Add("Button", "x1280 y110 w60 h20 Hidden", "Test")
MovementTestButton.OnEvent("Click", (*) => StartWalk(true))
MovementImport := MainUI.Add("Picture", "x820 y108 w20 h20 +BackgroundTrans Hidden", Import)
MovementImport.OnEvent("Click", (*) => ImportMovements())
MovementExport := MainUI.Add("Picture", "x845 y108 w20 h20 +BackgroundTrans Hidden", Export)
MovementExport.OnEvent("Click", (*) => ExportMovements(WalkMapDropdown.Text))

; === Custom Placement Settings ===
global CustomSettings := MainUI.Add("GroupBox", "x190 y632 w605 h60 +Center c" uiTheme[1], "Custom Placement Settings")
PlacementSettingsImportButton := AddUI("Picture", "x200 y652 w27 h27 +BackgroundTrans", Import, (*) => ImportCustomCoords())
PlacementSettingsExportButton := AddUI("Picture", "x235 y652 w27 h27 +BackgroundTrans", Export, (*) => ExportCustomCoords(CustomPlacementMapDropdown.Text))
CustomPlacementMap := MainUI.Add("Text", "x275 y655 w60 h20 +Left", "Map:")
global CustomPlacementMapDropdown := MainUI.Add("DropDownList", "x310 y653 w180 h200 Choose1 +Center", [
    "Custom",
    "Planet Namak",
    "Marine's Ford",
    "Karakura Town",
    "Shibuya",
    "Shibuya (Destroyed)", 
    "Demon District",
    "Nightmare Train - Act 1",
    "Nightmare Train - Act 2",
    "Nightmare Train - Act 3",
    "Halloween",
    "Spirit Invasion"
])

CustomPlacementButton := MainUI.Add("Button", "x495 y655 w85 h20", "Set")
CustomPlacementButton.OnEvent("Click", (*) => StartCoordinateCapture())
CustomPlacementClearButton := MainUI.Add("Button", "x595 y655 w85 h20", "Clear")
CustomPlacementClearButton.OnEvent("Click", (*) => DeleteCustomCoordsForPreset(CustomPlacementMapDropdown.Text))
fixCameraButton := MainUI.Add("Button", "x695 y655 w85 h20", "Fix Camera")
fixCameraButton.OnEvent("Click", (*) => BasicSetup(true))
; === End of Custom Placement Settings ===

GithubButton.OnEvent("Click", (*) => OpenGithub())
DiscordButton.OnEvent("Click", (*) => OpenDiscord())
;--------------SETTINGS--------------;
global modeSelectionGroup := MainUI.Add("GroupBox", "x808 y38 w500 h45 +Center Background" uiTheme[2], "Game Mode Selection")
MainUI.SetFont("s10 c" uiTheme[6])
global ModeDropdown := MainUI.Add("DropDownList", "x818 y53 w140 h180 Choose0 +Center", ["Story", "Infinity Castle", "Legend Stage", "Portal", "Raid", "Event", "Challenge", "Custom"])
global CustomCardDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden Choose1", ["Halloween", "Spirit Invasion"])
global EventDropdown:= MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Halloween", "Spirit Invasion"])
global EventRoleDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden Choose1", ["Solo", "Host", "Guest"])
global StoryDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Planet Namak", "Marine's Ford", "Karakura Town", "Shibuya", "Demon District"])
global StoryActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Infinite", "Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6"])
global LegendDropDown := MainUI.Add("DropDownlist", "x968 y53 w150 h180 Choose0 +Center", ["Shibuya (Destroyed)", "Nightmare Train"] )
global LegendActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Act 1", "Act 2", "Act 3"])
global RaidDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center", ["Amusement Park", "Test"])
global RaidActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6"])
global PortalDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Marine Ford", "Demon District"])
global PortalRoleDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Solo", "Host", "Guest"])
global ConfirmButton := MainUI.Add("Button", "x1218 y53 w80 h25", "Confirm")

LegendDropDown.Visible := false
RaidDropdown.Visible := false
RaidActDropdown.Visible := false
ReturnLobbyBox.Visible := false
Hotkeytext.Visible := false
Hotkeytext2.Visible := false
Hotkeytext3.Visible := false
ModeDropdown.OnEvent("Change", OnModeChange)
EventDropdown.OnEvent("Change", OnEventChange)
StoryDropdown.OnEvent("Change", OnStoryChange)
LegendDropDown.OnEvent("Change", OnLegendChange)
RaidDropdown.OnEvent("Change", OnRaidChange)
ConfirmButton.OnEvent("Click", OnConfirmClick)
;------MAIN UI------;

;------UNIT CONFIGURATION------UNIT CONFIGURATION------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/

AddUnitCard(MainUI, index, x, y) {
    unit := {}

    ; Helper for adding styled text
    AddText(ctrlX, ctrlY, width, height, options := "", text := "") {
        return MainUI.Add("Text", Format("x{} y{} w{} h{} {}", ctrlX, ctrlY, width, height, options), text)
    }

    ; Background and borders
    unit.Background     := AddText(x, y, 550, 45, "+Background" uiTheme[4])
    unit.BorderTop      := AddText(x, y, 550, 2, "+Background" uiTheme[3])
    unit.BorderBottom   := AddText(x, y + 45, 552, 2, "+Background" uiTheme[3])
    unit.BorderLeft     := AddText(x, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight    := AddText(x + 550, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight2   := AddText(x + 250, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight3   := AddText(x + 420, y, 2, 45, "+Background" uiTheme[3])

    ; Main Labels
    MainUI.SetFont("s11 Bold c" uiTheme[1])
    unit.EnabledTitle   := AddText(x + 30, y + 18, 60, 25, "+BackgroundTrans", "Unit " index)

    ; Unit Configuration
    MainUI.SetFont("s9 c" uiTheme[1])
    unit.PlacementText        := AddText(x + 90, y + 2, 80, 20, "+BackgroundTrans", "Placements")
    unit.PriorityText         := AddText(x + 185, y + 2, 60, 20, "BackgroundTrans", "Priority")

    MainUI.SetFont("s7 c" uiTheme[1])
    ;unit.PlaceAndUpgradeText := AddText(x + 258, y + 2, 250, 20, "BackgroundTrans", "Auto Upgrade After Placement")
    MainUI.SetFont("s9 c" uiTheme[1])
    unit.AutoUpgradeTitle         := AddText(x + 275, y + 5, 250, 25, "+BackgroundTrans", "Enable Auto Upgrade")
    unit.AutoAbilityTitle := AddText(x + 275, y + 25, 250, 25, "+BackgroundTrans", "Enable Auto Ability")

    if (!unitUpgradeLimitDisabled) {
        unit.UpgradeCapText := AddText(x + 440, y + 2, 250, 20, "BackgroundTrans", "Upgrade Limit")
        unit.UpgradeLimitTitle := AddText(x + 445, y + 20, 250, 25, "+BackgroundTrans", "Enabled")
    }

    UnitData.Push(unit)
    return unit
}


;Create Unit slot
y_start := 85
y_spacing := 50
Loop 6 {
    AddUnitCard(MainUI, A_Index, 808, y_start + ((A_Index-1)*y_spacing))
}

enabled1 := MainUI.Add("CheckBox", "x818 y105 w15 h15", "")
enabled2 := MainUI.Add("CheckBox", "x818 y155 w15 h15", "")
enabled3 := MainUI.Add("CheckBox", "x818 y205 w15 h15", "")
enabled4 := MainUI.Add("CheckBox", "x818 y255 w15 h15", "")
enabled5 := MainUI.Add("CheckBox", "x818 y305 w15 h15", "")
enabled6 := MainUI.Add("CheckBox", "x818 y355 w15 h15", "")

upgradeEnabled1 := MainUI.Add("CheckBox", "x1065 y90 w15 h15", "")
upgradeEnabled2 := MainUI.Add("CheckBox", "x1065 y140 w15 h15", "")
upgradeEnabled3 := MainUI.Add("CheckBox", "x1065 y190 w15 h15", "")
upgradeEnabled4 := MainUI.Add("CheckBox", "x1065 y240 w15 h15", "")
upgradeEnabled5 := MainUI.Add("CheckBox", "x1065 y290 w15 h15", "")
upgradeEnabled6 := MainUI.Add("CheckBox", "x1065 y340 w15 h15", "")

abilityEnabled1 := MainUI.Add("CheckBox", "x1065 y110 w15 h15", "")
abilityEnabled2 := MainUI.Add("CheckBox", "x1065 y160 w15 h15", "")
abilityEnabled3 := MainUI.Add("CheckBox", "x1065 y210 w15 h15", "")
abilityEnabled4 := MainUI.Add("CheckBox", "x1065 y260 w15 h15", "")
abilityEnabled5 := MainUI.Add("CheckBox", "x1065 y310 w15 h15", "")
abilityEnabled6 := MainUI.Add("CheckBox", "x1065 y360 w15 h15", "")

upgradeLimitEnabled1 := MainUI.Add("CheckBox", "x1235 y105 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled2 := MainUI.Add("CheckBox", "x1235 y155 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled3 := MainUI.Add("CheckBox", "x1235 y205 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled4 := MainUI.Add("CheckBox", "x1235 y255 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled5 := MainUI.Add("CheckBox", "x1235 y305 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled6 := MainUI.Add("CheckBox", "x1235 y355 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")

MainUI.SetFont("s8 c" uiTheme[6])

; Placement dropdowns
Placement1 := MainUI.Add("DropDownList", "x918 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement2 := MainUI.Add("DropDownList", "x918 y155 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement3 := MainUI.Add("DropDownList", "x918 y205 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement4 := MainUI.Add("DropDownList", "x918 y255 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement5 := MainUI.Add("DropDownList", "x918 y305 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement6 := MainUI.Add("DropDownList", "x918 y355 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])

Priority1 := MainUI.Add("DropDownList", "x980 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Priority1.OnEvent("Change", (*) => OnPriorityChange("Placement", 1, Priority1.Value))

Priority2 := MainUI.Add("DropDownList", "x980 y155 w35 h180 Choose2 +Center", ["1","2","3","4","5","6"])
Priority2.OnEvent("Change", (*) => OnPriorityChange("Placement", 2, Priority2.Value))

Priority3 := MainUI.Add("DropDownList", "x980 y205 w35 h180 Choose3 +Center", ["1","2","3","4","5","6"])
Priority3.OnEvent("Change", (*) => OnPriorityChange("Placement", 3, Priority3.Value))

Priority4 := MainUI.Add("DropDownList", "x980 y255 w35 h180 Choose4 +Center", ["1","2","3","4","5","6"])
Priority4.OnEvent("Change", (*) => OnPriorityChange("Placement", 4, Priority4.Value))

Priority5 := MainUI.Add("DropDownList", "x980 y305 w35 h180 Choose5 +Center", ["1","2","3","4","5","6"])
Priority5.OnEvent("Change", (*) => OnPriorityChange("Placement", 5, Priority5.Value))

Priority6 := MainUI.Add("DropDownList", "x980 y355 w35 h180 Choose6 +Center", ["1","2","3","4","5","6"])
Priority6.OnEvent("Change", (*) => OnPriorityChange("Placement", 6, Priority6.Value))

UpgradePriority1 := MainUI.Add("DropDownList", "x1020 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6",""])
UpgradePriority1.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 1, UpgradePriority1.Text))

UpgradePriority2 := MainUI.Add("DropDownList", "x1020 y155 w35 h180 Choose2 +Center", ["1","2","3","4","5","6",""])
UpgradePriority2.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 2, UpgradePriority2.Text))

UpgradePriority3 := MainUI.Add("DropDownList", "x1020 y205 w35 h180 Choose3 +Center", ["1","2","3","4","5","6",""])
UpgradePriority3.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 3, UpgradePriority3.Text))

UpgradePriority4 := MainUI.Add("DropDownList", "x1020 y255 w35 h180 Choose4 +Center", ["1","2","3","4","5","6",""])
UpgradePriority4.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 4, UpgradePriority4.Text))

UpgradePriority5 := MainUI.Add("DropDownList", "x1020 y305 w35 h180 Choose5 +Center", ["1","2","3","4","5","6",""])
UpgradePriority5.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 5, UpgradePriority5.Text))

UpgradePriority6 := MainUI.Add("DropDownList", "x1020 y355 w35 h180 Choose6 +Center", ["1","2","3","4","5","6",""])
UpgradePriority6.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 6, UpgradePriority6.Text))

; Upgrade Limit
UpgradeLimit1 := MainUI.Add("DropDownList", "x1310 y105 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])
UpgradeLimit2 := MainUI.Add("DropDownList", "x1310 y155 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])
UpgradeLimit3 := MainUI.Add("DropDownList", "x1310 y205 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])
UpgradeLimit4 := MainUI.Add("DropDownList", "x1310 y255 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])
UpgradeLimit5 := MainUI.Add("DropDownList", "x1310 y305 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])
UpgradeLimit6 := MainUI.Add("DropDownList", "x1310 y355 w45 h180 Choose1 +Center " (unitUpgradeLimitDisabled ? "Hidden" : ""), ["0","1","2","3","4","5","6","7","8","9"])

LoadUnitSettingsByMode()
MainUI.Show("w1366 h700")
WinMove(0, 0,,, "ahk_id " MainUIHwnd)
forceRobloxSize()  ; Initial force size and position
SetTimer(checkRobloxSize, 600000)  ; Check every 10 minutes
;------FUNCTIONS------;

AddToLog(current) {
    global processList, currentOutputFile, lastlog
    global WebhookLogsEnabled, WebhookEnabled

    ; Shift values downward and remove arrows
    loop processList.Length {
        i := processList.Length - A_Index + 1
        if (i > 1)
            processList[i].Value := StrReplace(processList[i - 1].Value, "➤ ", "")
    }

    ; Add new entry to the top
    processList[1].Value := "➤ " . current

    ; Optional: Log to file
    elapsedTime := getElapsedTime()
    Sleep(50)

    ; Remove emojis from the log string
    cleanCurrent := CleanString(current)

    ; Optional: Log to file
    elapsedTime := getElapsedTime()
    Sleep(50)
    FileAppend(cleanCurrent . " " . elapsedTime . "`n", currentOutputFile)

    ; Store last log and optionally send webhook
    lastlog := current
    if (WebhookLogsEnabled.Value && WebhookEnabled.Value && scriptInitialized)
        WebhookLog()
}

;Timer
getElapsedTime() {
    global StartTime
    ElapsedTime := A_TickCount - StartTime
    Minutes := Mod(ElapsedTime // 60000, 60)  
    Seconds := Mod(ElapsedTime // 1000, 60)
    return Format("{:02}:{:02}", Minutes, Seconds)
}

;Basically the code to move roblox, below

sizeDown() {
    global rblxID
    if !WinExist(rblxID)
        return

    WinActivate(rblxID)
    WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)

    if (OutWidth >= A_ScreenWidth && OutHeight >= A_ScreenHeight) {
        Send "{F11}"
        Sleep(150)
    }

    Loop 3 {
        WinMove(X, Y, targetWidth, targetHeight, rblxID)
        Sleep(100)
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth == targetWidth && OutHeight == targetHeight)
            return
    }

    AddToLog("Failed to resize Roblox window")
}

moveRobloxWindow() {
    global MainUIHwnd, offsetX, offsetY, rblxID
    
    if !WinExist(rblxID) {
        AddToLog("Waiting for Roblox window...")
        return
    }

    ; First ensure correct size
    sizeDown()
    
    ; Then move relative to main UI
    WinGetPos(&x, &y, &w, &h, MainUIHwnd)
    WinMove(x + offsetX, y + offsetY,,, rblxID)
    WinActivate(rblxID)
}

forceRobloxSize() {
    global rblxID
    
    if !WinExist(rblxID) {
        checkCount := 0
        While !WinExist(rblxID) {
            Sleep(5000)
            if(checkCount >= 5) {
                AddToLog("Attempting to locate the Roblox window")
            } 
            checkCount += 1
            if (checkCount > 12) { ; Give up after 1 minute
                AddToLog("Could not find Roblox window")
                return
            }
        }
        AddToLog("Found Roblox window")
    }

    WinActivate(rblxID)
    sizeDown()
    moveRobloxWindow()
}

; Function to periodically check window size
checkRobloxSize() {
    global rblxID
    if WinExist(rblxID) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth != targetWidth || OutHeight != targetHeight) {
            sizeDown()
            moveRobloxWindow()
        }
    }
}

checkSizeTimer() {
    if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, "ahk_exe RobloxPlayerBeta.exe")
        if (OutWidth != 816 || OutHeight != 638) {
            AddToLog("Fixing Roblox window size")
            moveRobloxWindow()
        }
    }
}

UpdateTooltip() {
    global waitingForClick
    if waitingForClick {
        MouseGetPos &x, &y
        ToolTip "Click anywhere to save coordinates...", x + 5, y - 5  ; Offset tooltip slightly
    } else {
        ToolTip()  ; Hide tooltip when not waiting
        SetTimer UpdateTooltip, 0  ; Stop the timer
    }
}

~LShift::
{
    global waitingForClick, recording
    if waitingForClick {
        AddToLog("Stopping coordinate capture")
        if (WaitingFor("Placements")) {
            SaveCustomPlacements()
        }
        RemoveWaiting()
        ShowPlacements(false)
    }
    if (recording) {
        StopRecordingWalk()
    }
}

~LButton::
{
    global waitingForClick, savedCoords
    global nukeCoords
    global placement1, placement2, placement3, placement4, placement5, placement6

    if !scriptInitialized
        return

    if waitingForClick {
        if (WaitingFor("Nuke")) {
            MouseGetPos(&x, &y)
            SetTimer(UpdateTooltip, 0)
            nukeCoords := {x: x, y: y}
            ToolTip("Nuke Coords Set", x + 10, y + 10)
            AddToLog("📌 Nuke Ability Coordinates Saved → X: " x ", Y: " y)
            SetTimer(ClearToolTip, -1200)
            RemoveWaiting()
        }
        else {
            mode := ModeDropdown.Text
            mapName := (mode = "Event") ? EventDropdown.Text : CustomPlacementMapDropdown.Text

            if (mapName = "") {
                AddToLog("⚠️ No map selected.")
                return
            }

            MouseGetPos(&x, &y)
            SetTimer(UpdateTooltip, 0)

            coords := GetOrInitCustomCoords(mapName)
            coords.Push({ x: x, y: y, mapName: mapName })
            savedCoords[mapName] := coords

            ToolTip("Coords Set: " coords.Length, x + 10, y + 10)
            AddToLog("📌 [Map: " mapName "] Saved → X: " x ", Y: " y " | Set: " coords.Length)
            SetTimer(ClearToolTip, -1200)
        }
    }
}

ClearToolTip() {
    ToolTip()  ; Properly clear tooltip
    Sleep 100  ; Small delay to ensure clearing happens across all systems
    ToolTip()  ; Redundant clear to catch edge cases
}

InitControlGroups() {
    global ControlGroups

    ControlGroups["Unit"] := []

    Blacklist := [""]

    for name in ["Placement", "enabled", "priority", "upgradePriority", "upgradeEnabled", "upgradeLimitEnabled", "upgradeLimit", "abilityEnabled"] {
        loop 6 {
            varName := name . A_Index
            baseName := RegExReplace(varName, "\d+$")
            
            ; Check if baseName is in Blacklist manually
            isBlacklisted := false
            for index, item in Blacklist {
                if (item = baseName) {
                    isBlacklisted := true
                    break
                }
            }
            
            if (isBlacklisted)
                continue

            if IsSet(%varName%)  ; Check if the variable exists
                ControlGroups["Unit"].Push(%varName%)
            else
                AddToLog("Variable " . varName . " does not exist!")
        }
    }

    ControlGroups["Settings"] := [
        WebhookBorder, WebhookEnabled, WebhookLogsEnabled, WebhookURLBox,
        PrivateSettingsBorder, PrivateServerEnabled, PrivateServerURLBox, PrivateServerTestButton, PrivateServerGuideButton, MatchmakingFailsafe, MatchmakingFailsafeTimer, MatchmakingFailsafeTimerText,
        KeybindBorder, F1Text, F1Box, F2Text, F2Box, F3Text, F3Box, F4Text, F4Box, keybindSaveBtn,
        ZoomSettingsBorder, ZoomText, ZoomBox, ZoomTech, ZoomInOption,
        MiscSettingsBorder, UpdateChecker
    ]

    ControlGroups["Upgrade"] := [
        UpgradeBorder, UnitManagerUpgradeSystem, PriorityUpgrade
    ]

    ControlGroups["Mode"] := [
        ModeBorder, ModeConfigurations,
        StoryBorder, StoryDifficultyText, StoryDifficulty,
    ]

    ControlGroups["Placement"] := [
        UnitBorder,
        PlacementBorder
    ]

    ControlGroups["Event"] := [
        EventBorder, HalloweenMovement
    ]

    ControlGroups["Story"] := [
        StoryBorder, StoryDifficultyText, StoryDifficulty
    ]

    ControlGroups["Portal"] := [
        PortalBorder, FarmMorePortals
    ]

    ControlGroups["Challenge"] := [
        ChallengeBorder, ChallengeTeamSwap, ChallengeTeamText, ChallengeTeam, NormalTeamText, NormalTeam
    ]

    ControlGroups["Cards"] := [
        CardBorder, SpiritInvasionCardText, SpiritInvasionCardButton, HalloweenCardText, HalloweenCardButton
    ]

    ControlGroups["Nuke"] := [
        NukeBorder, NukeUnitSlotEnabled, NukeUnitSlot, NukeCoordinatesText, NukeCoordinatesButton, NukeAtSpecificWave, NukeWave, NukeDelayText, NukeDelay
    ]

    ControlGroups["Map Movement"] := [
        CustomWalkBorder, WalkMapText, WalkMapDropdown, MovementSetButton, MovementClearButton, MovementTestButton, MovementImport, MovementExport
    ]
}

ShowOnlyControlGroup(groupName) {
    global ControlGroups
    if !ControlGroups.Has(groupName) {
        return false
    }

    for name, groupControls in ControlGroups {
        shouldShow := (name = groupName)
        for ctrl in groupControls {
            if IsObject(ctrl)
                ctrl.Visible := shouldShow
        }
    }
    return true
}

ToggleControlGroup(groupName) {
    global ActiveControlGroup
    if (groupName = "Mode") {
        ActiveControlGroup := "Mode"
    }
    else if (groupName = "Settings") {
        if (ActiveControlGroup = "Settings") {
            groupName := "Unit"
            ActiveControlGroup := "Unit"
        } else {
            ActiveControlGroup := "Settings"
        }
    }
    else {
        ActiveControlGroup := groupName
    }
    if (ShowOnlyControlGroup((groupName = "Mode" ? ModeDropdown.Text = "" ? groupName : ModeDropdown.Text : groupName))) {
        SetUnitCardVisibility((groupName = "Unit") ? true : false)
    }
}

SetUnitCardVisibility(visible) {
    for _, unit in UnitData {
        for _, ctrl in unit.OwnProps() {
            if IsObject(ctrl)
                ctrl.Visible := visible
        }
    }

    for name in ["Placement", "enabled", "upgradeEnabled", "Priority"] {
        loop 6 {
            ctrl := %name%%A_Index%
            if IsObject(ctrl)
                ctrl.Visible := visible
        }
    }
}

ValidateWebhook() {
    url := WebhookURLBox.Value
    
    if (url == "") {
        WebhookEnabled.Value := false
        WebhookURLBox.Value := ""
        MsgBox("Webhook URL cannot be blank. Please enter a valid Webhook URL.", "Missing URL", "+0x1000")
        return
    }
    
    if (!RegExMatch(url, "^https://discord\.com/api/webhooks/.*")) {
        WebhookEnabled.Value := false
        WebhookURLBox.Value := ""
        MsgBox("Invalid Webhook URL! Please ensure it follows the correct format.", "Invalid URL", "+0x1000")
        return
    }
}

ValidateEditBox(ctrl) {
    val := Trim(ctrl.Value)
    ; If the input is not a number, reset to 0
    if !IsInteger(val)
    {
        ctrl.Value := "0"
        return
    }

    ; Convert to integer
    num := Integer(val)

    if (num < 0)
        ctrl.Value := "0"

    if (ctrl == ZoomBox) {
        if (num > 20)
            ctrl.Value := "20"  ; Limit to a maximum of 20
    }
}

OpenCoordinateEditor() {
    
}