#Requires AutoHotkey v2.0

StartBossRush() {

    while !(ok := isMenuOpen("Boss Rush")) {
        WalkToBossRush()
    }

    if (BossRushDropdown.Text = "Traits Disabled") {
        FixClick(470, 420)
        Sleep(500)
    }

    FixClick(335, 468)
    Sleep(1500)
    PlayHereOrMatchmake()
    RestartStage()
}

WalkToBossRush() {
    Teleport("Challenge")
    Walk("a", 3700)
    Walk("w", 6500)
    Walk("d", 3000)
    Walk("w", 3100)
    SendInput("E")
    Sleep(2300)
    FixClick(413, 521)
    Sleep(1500)
}

SelectBossModifier() {
    modifier := BossRushModifierDropdown.Text
    if (modifier = "Slot") {
        FixClick(268, 341)
    }
    else if (modifier = "Damage") {
        FixClick(408, 341)
    }
    else if (modifier = "Placement") {
        FixClick(547, 341)
    }
}