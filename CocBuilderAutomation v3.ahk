#Requires AutoHotkey v2
DllCall("SetThreadDpiAwarenessContext", "ptr", -3)

#include "libs\v3_setups.ahk"
#include "libs\v3_attack.ahk"
#include "libs\v3_utils.ahk"
#include "Object2Str.ahk"
SendMode "Event"
SetMouseDelay 10
SetDefaultMouseSpeed 1

`:: ExitApp

debug := 0 ;askInputBox("Debug?", 0)
starTarget := askInputBox("Star Target: 0-3", 3)
battleCycles := askInputBox("Cycles to run:", 300)
game := systemSetup()

;-------------AUTOMATION START-------------

activateWindow()
message "Initializing...", "objective"
message "zooming out", "progress"
sleep 200
Send "{Down down}"
sleep 1000
Send "{Down up}"
sleep 200

loop battleCycles {
    if Mod(A_Index, 5) == 0{
        activateWindow()
        message "Collecting Elixir", "objective"
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

    message "Running attack " A_Index "/" battleCycles, "objective"
    runAttack(starTarget)
}

ExitApp
;-------------AUTOMATION ENDS-------------


systemSetup() {

    ControlGetPos &OutX, &OutY, &OutWidth, &OutHeight, device.control, device.window
    WinGetPos &WindowOutX, &WindowOutY, &WindowOutWidth, &WindowOutHeight, device.window


    desiredWindowX := WindowOutWidth
    desiredWindowY := WindowOutHeight - OutHeight + device.standard.controlHeight * (OutWidth / device.standard.controlWidth)

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
