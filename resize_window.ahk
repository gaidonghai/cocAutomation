#Requires AutoHotkey v2
DllCall("SetThreadDpiAwarenessContext", "ptr", -3)

#include "libs\v3_setups.ahk"

ControlGetPos &OutX, &OutY, &OutWidth, &OutHeight, device.control, device.window
WinGetPos &WindowOutX, &WindowOutY, &WindowOutWidth, &WindowOutHeight, device.window


desiredWindowX := WindowOutWidth - OutWidth + device.standard.controlWidth
desiredWindowY := WindowOutHeight - OutHeight + device.standard.controlHeight

WinActivate device.window
WinMove(, , desiredWindowX, desiredWindowY, device.window)

ExitApp