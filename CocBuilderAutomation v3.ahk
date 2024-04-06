BackSpace:: ExitApp
#include "v3_setups.ahk"
SendMode "Event"
SetMouseDelay 10
SetDefaultMouseSpeed 1
WinMove(, , device.windowWidth, device.windowHeight, device.windowTitle)
debug := false

battleLength := 4
starTarget := 3
battleCycles := 300
if (1) {
    message "system setup", "objective"

    IB := InputBox("Battle length: (x15 secs)", "Battle options", "", battleLength)
    if IB.Result == "Cancel" {
        ExitApp
    }
    battleLength := IB.Value

    IB := InputBox("Star Target: 1-3", "Battle options", "", starTarget)
    if IB.Result == "Cancel" {
        ExitApp
    }
    starTarget := IB.Value

    IB := InputBox("Cycles to run:", "Battle options", "", battleCycles)
    if IB.Result == "Cancel" {
        ExitApp
    }
    battleCycles := IB.Value
}
;-------------AUTOMATION START-------------


initialize()
loop battleCycles {
    if Mod(A_Index, 5) == 1 {
        message "Collecting Elixir", "objective"
        collectElixir()
    }

    message "Running attack " A_Index "/" battleCycles, "objective"
    runAttack(battleLength)
}
ExitApp

initialize() {
    ;set zoom and run a test attack
    activateWindow()
    message "Initializing...", "objective"

    message "zooming out", "progress"
    sleep 200
    Send "{Down down}"
    sleep 1000
    Send "{Down up}"
    sleep 200

    message "run an attack with minimum zoom", "progress"
    runAttack(0)
}


activateWindow() {
    WinActivate device.windowTitle
}

collectElixir() {
    activateWindow()

    message "searching for elixir cart", "progress"
    secureDrag(game.elixir.drag[1], game.elixir.drag[2])
    sleep 200

    if checkCriteria(game.elixir.cart, 1000, &Px, &Py) {
        message "open elixir cart", "progress"
        sleep 200
    } else {
        ;Msgbox "!!!elixir cart not found. Quit process."
        return
    }

    secureClick [Px, Py]
    sleep 200
    if checkCriteria(game.elixir.close) {
        message "collect elixir", "progress"
        secureClick game.elixir.collect
        secureClick game.elixir.close.center
    } else {
        ;msgbox "!!!Cart window not found. Quit process"
        return
    }
}


runAttack(battleLength) {
    startAttack()

    message "deploy hero", "progress"
    secureClick game.army.hero
    secureDeploy(1)

    if battleLength > 0 {
        message "deploy troops", "progress"
        clickTroop(1)
        secureDeploy(8)

        message "activate troop ability", "progress"
        clickTroop(8)
    }

    loop battleLength {
        message "battle stage:" A_Index "/" battleLength, "progress"
        if (fight(A_Index == 1 ? 10000 : 15000, starTarget)) {
            break
        }
        secureClick game.army.hero
    }

    quitAttack()
}

startAttack() {

    while true {
        ;two possible conditions here
        ; if at home(normal situation), attack button will be found and clicked
        ; if at enemy base now (maybe due to a late cancel), attack button searching timeout and enemybase checking will follow
        ; if neither, wait and loop

        ;search for the attack button for 1 second: if successful, click it
        message "search for attack button", "progress"
        if checkCriteria(game.attack.attackButtonCriteria, 5000) { ;orange at attack button
            message "ready to attack", "progress"
            secureClick game.attack.button
            secureClick game.attack.start
            message "attack launched", "progress"
        }

        ;wait for enemy base to appear for 1 second:
        ; if successful, return true and finish
        ; otherwise, click cancel button
        message "search for enemy base", "progress"
        if checkCriteria(game.attack.enemyBaseCriteria, 10000) { ;purple at troop #1
            message "at enemy base", "progress"
            return true
        } else {
            message "attack timeout, try again", "progress"
            secureClick game.attack.cancel ;click cancel and try again
        }

        if(A_Index>1) {
            unstuck()
        }
    }
}

unstuck() {
    message "try to unstuck by escape", "progress"
    loop 3 {
        Send "{Escape}"
        sleep 200
    }
    secureClick game.exitDialog.cancel
}

fight(duration, starTarget := 1) {
    startTime := A_TickCount
    starCount := 0
    while A_TickCount - startTime <= duration {
        message "current stage: " A_TickCount - startTime ", current stars: " starCount "/" starTarget, "detail"

        if checkCriteria(game.surrender.battleEndCriteria) || starCount >= starTarget {
            message "", "detail"
            return true
        }

        if (checkCriteria(game.attack.starCriterias[starCount + 1])) {
            starCount++
        }
    }
    message "", "detail"
    return false

}


quitAttack() {
    while true {
        message "try to leave", "progress"
        secureClick game.surrender.button
        secureClick game.surrender.okay
        if checkCriteria(game.surrender.battleEndCriteria, 1000) {
            message "battle end dialog appeared", "progress"
            while true {
                secureClick game.surrender.returnHome
                message "wait for attack button to appear", "progress"
                if checkCriteria(game.attack.attackButtonCriteria, 5000) {
                    message "yes, at home", "progress"
                    return true
                } else {
                    message "try click return home button again"
                }
            }
        } else {
            message "return dialog not detected, wait and retry", "progress"
            sleep 1000
        }
    }
}


clickTroop(troopCount := 1) {
    loop troopCount {
        x := game.army.troopX + game.army.troopXinc * (A_Index - 1)
        y := game.army.troopY
        secureClick [x, y], 10
    }
}

secureDeploy(times := 8) {
    for coordinate in game.deploy {
        loop times {
            secureClick coordinate, 10
        }
    }
}


secureClick(xy, delay := 200, button := "Left")
{
    x := xy[1]
    y := xy[2]

    activateWindow()
    Click x + Random(-5, 5), y + Random(-5, 5), button
    sleep Random(delay, delay * 2)
}

secureDrag(xy1, xy2, speed := 20) {
    x1 := xy1[1]
    y1 := xy1[2]
    x2 := xy2[1]
    y2 := xy2[2]

    activateWindow()
    rx := Random(-5, 5)
    ry := Random(-5, 5)
    MouseMove x1 + rx, y1 + ry
    MouseClickDrag "Left", x1 + rx, y1 + ry, x2 + rx, y2 + ry, speed
}


checkCriteria(criteriaObject, timeout := 0, &Px := unset, &Py := unset) {
    ;return false if timeout occur
    ;Use tooltip 11
    startTime := A_TickCount

    while true {
        if securePixelSearch(&Px, &Py, criteriaObject) {
            message "", "debug"
            return true
        } else {
            if timeout > 0 {
                message "searching color: " A_TickCount - startTime, "debug"
            }
        }
        if (A_TickCount - startTime > timeout) {
            break
        }
    }
    message "", "debug"
    return false

    securePixelSearch(&Px, &Py, criteriaObject, variation := 16) {

        center := criteriaObject.center
        range := criteriaObject.range
        color := criteriaObject.color
        x1 := Max(center[1] - range[1], device.xBorder[1])
        y1 := Max(center[2] - range[2], device.yBorder[1])
        x2 := Min(center[1] + range[1], device.screenWidth - device.xBorder[2])
        y2 := Min(center[2] + range[2], device.screenHeight - device.yBorder[2])

        if (debug) {
            centerX := Round((x1 + x2) / 2)
            centerY := Round((y1 + y2) / 2)
            MouseMove centerX, centerY
        }
        activateWindow()
        return PixelSearch(&Px, &Py, x1, y1, x2, y2, color, 16)
    }
}

getColorString(xy) {
    x := xy[1]
    y := xy[2]
    return x "," y ": " PixelGetColor(x, y)
}

message(text, messageType := "") {
    t := 1
    switch messageType {
        case "objective": t := 2
        case "progress": t := 3
        case "detail": t := 4
        case "debug": t := 5
    }

    activateWindow()
    x := 0
    y := (t - 1) * 50
    ToolTip(text, x, y, t)
}