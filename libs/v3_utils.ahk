
activateWindow() {
    WinActivate device.window
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
        x1 := correctX(center[1] - range[1])
        y1 := correctY(center[2] - range[2])
        x2 := correctX(center[1] + range[1])
        y2 := correctY(center[2] + range[2])
        activateWindow()
        return PixelSearch(&Px, &Py, x1, y1, x2, y2, color, variation)
    }
}

message(text, messageType := 0, timeout:=0) {
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

    if(timeout>0) {
        SetTimer () => ToolTip("",x,y,t), -timeout
    }
}



correctX(x) {
    x:=max(x,device.xBorder[1])
    x:=min(x,device.controlWidth - device.xBorder[2])
    return x
}
correctY(y) {
    y:=max(y,device.yBorder[1])
    y:=min(y,device.controlHeight - device.yBorder[2])
    return y
}