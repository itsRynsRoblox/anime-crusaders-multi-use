#Requires AutoHotkey v2.0

StartInfinityCastle() {

    while !(ok := isMenuOpen("Infinity Castle")) {
        WalkToInfinityCastle()
    }

    FixClick(530, 455) ; Enter Infinity Castle

    while (isInLobby()) {
        Sleep(100)
    }
    RestartStage()
}

WalkToInfinityCastle() {
    Walk("w", 4000)
    Walk("a", 4200)
}

ClickNextRoom(testing := false) {
    while (isMenuOpen("End Screen")) {
        pixelChecks := [{ color: 0xFCE560, x: 270, y: 483 }]

        for pixel in pixelChecks {
            if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
                FixClick(pixel.x, pixel.y, (testing ? "Right" : "Left"))
                if (testing) {
                    Sleep(1500)
                }
            }
        }
    }
}