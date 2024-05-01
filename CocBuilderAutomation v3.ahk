#Requires AutoHotkey v2
DllCall("SetThreadDpiAwarenessContext", "ptr", -3)

#include "v3_setups.ahk"
#include "Object2Str.ahk"
SendMode "Event"
SetMouseDelay 10
SetDefaultMouseSpeed 1

`:: ExitApp

debug := askInputBox("Debug?", 0)
resizeWindowToSetup := askInputBox("Resize Window?", 0)
battleLength := askInputBox("Battle length: (x15 secs)", 4)
starTarget := askInputBox("Star Target: 1-3", 3)
battleCycles := askInputBox("Cycles to run:", 300)
game := systemSetup()


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
    WinActivate device.window
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

    starCount := 0
    loop battleLength {
        startTime := A_TickCount
        currentStage := A_Index
        duration := currentStage == 1 ? 10000 : 15000

        while A_TickCount - startTime <= duration {
            message "battle stage:" currentStage "/" battleLength "(" A_TickCount - startTime "), current stars: " starCount "/" starTarget, "progress"
            if checkCriteria(game.surrender.battleEndCriteria) || starCount >= starTarget {
                message "", "progress"
                break 2 ;quit two levels to end this attack
            }

            if (checkCriteria(game.attack.starCriterias[starCount + 1])) {
                starCount++
            }
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

        if (A_Index > 1) {
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
                    message "try click return home button again", "progress"
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
    startTime := A_TickCount

    while true {
        if (debug) {
            message Format("Searching color {1:#X}, get {2} ({3})", criteriaObject.color, PixelGetColorXY(criteriaObject.center), A_TickCount - startTime), "detail"

        }

        if securePixelSearch(&Px, &Py, criteriaObject) {
            ;message "", "detail"
            return true
        }

        if (A_TickCount - startTime >= timeout) {
            ;message "", "detail"
            return false
        }
    }

    PixelGetColorXY(xy) {
        x := xy[1]
        y := xy[2]
        if (debug) {
            MouseMove x, y
        }
        return PixelGetColor(x, y)
    }

    securePixelSearch(&Px, &Py, criteriaObject, variation := 16) {
        center := criteriaObject.center
        range := criteriaObject.range
        color := criteriaObject.color
        x1 := Max(center[1] - range[1], device.xBorder[1])
        y1 := Max(center[2] - range[2], device.yBorder[1])
        x2 := Min(center[1] + range[1], device.controlWidth - device.xBorder[2])
        y2 := Min(center[2] + range[2], device.controlHeight - device.yBorder[2])
        activateWindow()
        return PixelSearch(&Px, &Py, x1, y1, x2, y2, color, variation)
    }
}


message(text, messageType := 0) {
    t := 1
    switch messageType {
        case "objective": t := 2
        case "progress": t := 3
        case "detail": t := 4
        case "debug": t := 5
        default: t := messageType
    }

    activateWindow()
    x := device.xBorder[1]
    y := device.yBorder[1] + (t - 1) * 50
    ToolTip(text, x, y, t)
}


systemSetup() {


    ControlGetPos &OutX, &OutY, &OutWidth, &OutHeight, device.control, device.window
    WinGetPos &WindowOutX, &WindowOutY, &WindowOutWidth, &WindowOutHeight, device.window

    if (resizeWindowToSetup) {
        desiredWindowX := WindowOutWidth - OutWidth + device.standard.controlWidth
        desiredWindowY := WindowOutHeight - OutHeight + device.standard.controlHeight
    } else {
        desiredWindowX := WindowOutWidth
        desiredWindowY := WindowOutHeight - OutHeight + device.standard.controlHeight * (OutWidth / device.standard.controlWidth)
    }

    if(debug) {
        msgbox desiredWindowX "," desiredWindowY
    }

    activateWindow()
    WinMove(, , desiredWindowX, desiredWindowY, device.window)

    ControlGetPos &OutX, &OutY, &OutWidth, &OutHeight, device.control, device.window

    device.controlWidth := OutWidth
    device.controlHeight := OutHeight
    device.xBorder := [OutX, WindowOutWidth - OutWidth - OutX]
    device.yBorder := [OutY, WindowOutHeight - OutHeight - OutY]

    game := generateGameObject()

    if (debug) {
        MsgBox(Object2Str(device))
        MsgBox(Object2Str(game))
    }

    return game
}

askInputBox(question, defaultValue) {
    IB := InputBox(question, "Automation options", "", defaultValue)
    if IB.Result == "Cancel" {
        ExitApp
    }
    return IB.Value
}