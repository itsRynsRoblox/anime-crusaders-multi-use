#Requires AutoHotkey v2.0

StartSpiritInvasion() {

    Teleport("Spirit Invasion")
    Sleep(1000)

    while !(ok := isMenuOpen("Spirit Invasion")) {
        SendInput("E")
        Sleep(2500)
        FixClick(412, 523) ; Click Continue
        Sleep(1500)
    }

    FixClick(470, 470) ; click play
    Sleep(1500)
    PlayHereOrMatchmake()
    RestartStage()
}