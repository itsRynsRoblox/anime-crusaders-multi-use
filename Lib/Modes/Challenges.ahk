#Requires AutoHotkey v2.0


StartChallenge(maxAttempts := 5) {
    attempts := 0

    while (attempts < maxAttempts && !(ok := isMenuOpen("Matchmaking"))) {
        WalkToChallengeRoom()
        attempts += 1
    }

    if (attempts >= maxAttempts) {
        AddToLog("Failed to start challenge after " attempts " attempts. Giving up.")
        SetChallengeCooldown()
        return
    }

    AddToLog("Starting Challenge")
    FixClick(330, 350)
    Sleep(500)
    FixClick(410, 525) ; click play
    SetChallengeCooldown()
    RestartStage()
}

WalkToChallengeRoom() {
    Teleport("Challenge")
    Walk("d", 10000)
    Walk("w", 5000)
}

TimeForChallenge() {
    return AutoChallenge.Value && !IsChallengeOnCooldown()
}