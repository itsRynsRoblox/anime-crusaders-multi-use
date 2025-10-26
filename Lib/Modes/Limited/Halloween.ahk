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

isWrongHalloweenAngle() {
    return GetPixel(0x2D0109, 47, 121, 2, 2, 10)
}

FixHalloweenAngle() {
    if (isWrongHalloweenAngle() && EventDropdown.Text = "Halloween" && !isInChallenge()) {
        loop 2 {
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
        }
      ;  Zoom()
    }
}