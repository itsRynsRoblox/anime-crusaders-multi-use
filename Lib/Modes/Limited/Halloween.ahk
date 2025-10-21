#Requires AutoHotkey v2.0

StartHalloween(skipLobby := false) {
    if (!skipLobby) {
        while !(ok := isMenuOpen("Halloween")) {
            WalkToHalloween()
        }
        FixClick(473, 473) ; click play
        PlayHereOrMatchmake()
    }
    RestartStage()
}

WalkToHalloween() {
    Teleport("Challenge")
    Walk("a", 3700)
    Walk("w", 6600)
    SendInput("e")
    Sleep(2300)
    FixClick(413, 521)
    Sleep(1500)
}

WalkDownPath() {
    Walk("s", 5500)
    if (EventRoleDropdown.Text != "Guest") {
        Walk("d", 300)
    }
}