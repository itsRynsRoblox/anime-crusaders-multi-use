#Requires AutoHotkey v2.0

StartGates() {
    while !(ok := isMenuOpen("Gates")) {
        WalkToGates()
    }

    SelectGatesByFindText()
    Sleep(500)
    PlayHereOrMatchmake()
    RestartStage()
}

WalkToGates() {
    Teleport("Challenge")
    Walk("a", 3700)
    Walk("w", 6500)
    SendInput("e")
    Sleep(2300)
    FixClick(413, 521)
    Sleep(1500)
}

SelectGatesByFindText() {
    global currentGateRank
    coordsTop := [
        [162, 257, 281, 274],
        [297, 256, 420, 275],
        [435, 258, 558, 272]
    ]

    coordsBottom := [
        [162, 257, 281, 274],
        [297, 256, 420, 275],
        [435, 258, 558, 272]
    ]

    mouseCoords := [
        [226, 474], [368, 473], [500, 478],
        [236, 472], [374, 471], [511, 472]
    ]

    GatePatterns := Map(
        "National Rank", NationalRank,
        "S Rank", SRank,
        "A Rank", ARank,
        "B Rank", BRank,
        "C Rank", CRank,
        "D Rank", DRank
    )

    gatePriorityOrder := ["National Rank", "S Rank", "A Rank", "B Rank", "C Rank", "D Rank"]

    AddToLog("Scanning all gates in priority order")

    foundGates := [] ; array to hold found gates info: {priority, X, Y, inTop}

    ; Helper function to scan coords and add found gates
    ScanCoords(coords, inTop) {
        for _, coord in coords {
            x1 := coord[1], y1 := coord[2], x2 := coord[3], y2 := coord[4]
            foundInThisCoord := false

            loop 5 { ; Retry up to 5 times
                for _, priorityGate in gatePriorityOrder {
                    pattern := GatePatterns.Get(priorityGate)
                    if (ok := FindText(&X, &Y, x1, y1, x2, y2, 0.05, 0.05, pattern)) {
                        foundGates.Push({ priority: priorityGate, X: X, Y: Y, inTop: inTop })
                        foundInThisCoord := true
                        break ; Found a gate in this attempt, skip to next coord
                    }
                }
                if (foundInThisCoord)
                    break
                Sleep(200) ; Wait a bit before retrying
            }
        }
    }

    ; 1. Scan top coords
    ScanCoords(coordsTop, true)
    MouseMove(433, 504)

    ; 2. Scroll down and scan bottom coords
    Scroll(3, "WheelDown", 100)
    Sleep (500)
    ScanCoords(coordsBottom, false)
    
    ; Debug: Log all found gates
    for index, gate in foundGates {
        section := gate.inTop ? "Top" : "Bottom"
        AddToLog(Format("[{}] {} at X:{} Y:{}", section, gate.priority, gate.X, gate.Y))
    }

    ; 3. Pick best gate according to priority order
    bestGate := ""
    bestX := 0
    bestY := 0
    bestIndex := 0
    bestInTop := false

    for priority, priorityGate in gatePriorityOrder {
        for index, gate in foundGates {
            if (gate.priority == priorityGate) {
                bestGate := gate.priority
                bestX := gate.X
                bestY := gate.Y
                bestInTop := gate.inTop
                bestIndex := index
                break 2 ; stop searching as we found best gate per priority order
            }
        }
    }

    if (bestGate != "") {
        AddToLog(Format("Best gate found: {} at X:{} Y:{}", bestGate, bestX, bestY))

        if (bestInTop) {
            Scroll(3, "WheelUp", 100)
        }
        currentGateRank := bestGate
        SelectGate(bestIndex, mouseCoords)
        return
    }

    AddToLog("Failed to pick a gate")
}

; === Selects card by index and scroll direction
SelectGate(index, mouseCoords) {
    if (index > 3) {
        Scroll(5, "WheelDown", 5)
    } else {
        Scroll(5, "WheelUp", 5)
    }
    Sleep(1500)
    FixClick(mouseCoords[index][1], mouseCoords[index][2])
    return index
}

; Calculates similarity between two strings using Levenshtein
FuzzyMatch(str1, str2) {
    return 1.0 - (Levenshtein(str1, str2) / Max(StrLen(str1), StrLen(str2)))
}

PickNextGate(testing := false) {
    while (isMenuOpen("End Screen")) {
        pixelChecks := [{ color: 0xFADE57, x: 312, y: 480 }]

        for pixel in pixelChecks {
            if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
                FixClick(pixel.x, pixel.y, (testing ? "Right" : "Left"))
                if (testing) {
                    Sleep(1500)
                }
            }
        }
    }
    SelectGatesByFindText()
    Sleep (500)
    PlayHereOrMatchmake()
}

WalkToCenterOfGateRoom() {
    Walk("s", 3400)
    Walk("d", 1000)
    Walk("s", 800) ; walks to rocks south
}

HandleGateEnd() {
    global lastResult

    if (TimeForChallenge()) {
        AddToLog("[Info] Game over, starting challenge")
        return ClickReturnToLobby()
    }
    AddToLog("[Info] Game over, selecting next gate")
    PickNextGate()
    return RestartStage()
}