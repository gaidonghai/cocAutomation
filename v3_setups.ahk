device := {
    name: "bluestacks",
    window: "BlueStacks Android 11",
    control: "BlueStacksApp1",
    standard : {
        controlWidth: 1920,
        controlHeight: 1080,
        xBorder: [1, 1],
        yBorder: [49, 1],
    }
}




generateGameObject() {

    return {
        exitDialog: {
            cancel: xy([750, 750])
        },
        elixir: {
            drag: [xy([900, 200]), xy([900, 1000])],
            cart: {
                center: xy([1300, 700]),
                range: mag([300, 300]),
                color: 0xb77e4f
            },
            collect: xy([1415, 960]),
            close: {
                center: xy([1610, 155]),
                range: mag([20, 20]),
                color: 0xE12025
            }
        },
        attack: {
            button: xy([125, 1000]),
            start: xy([1430, 750]),
            cancel: xy([950, 1000]),
            enemyBaseCriteria: {
                center: xy([390, 950]),
                range: mag([30, 10]),
                color: 0xBB3CEE
            },
            attackButtonCriteria: {
                center: xy([50, 980]),
                range: mag([10, 10]),
                color: 0xDB8C30
            },
            starCriterias: generateStarCriterias(),
        },
        surrender: {
            button: xy([135, 800]),
            okay: xy([1170, 750]),
            returnHome: xy([960, 960]),
            battleEndCriteria: {
                center: xy([961, 938]), ;y level is critical
                range: mag([100, 3]),
                color: 0xB3DB85
            }
        },
        army: {
            hero: xy([195, 1000]),
            troopX: x(365),
            troopXinc: x(150,false),
            troopY: y(1050)
        },
        deploy: [
            xy([35, 700]),
            xy([300, 200])
        ]
    }

    generateStarCriterias() {
        
        colorA := 0xDD962C ;Yellow
        colorB := 0XAED0E3 ;Silver
        
        r := []
        loop 6 {
            r.push {
                center: xy([1630 + Mod(A_Index - 1, 3) * 53, 860]),
                range: mag([5, 5]),
                color: A_Index < 4 ? colorA : colorB
            }
        }
        return r
    }

    x(x, absoluteCoordinate := true) {
        if (absoluteCoordinate) {
            x -= device.standard.xBorder[1]
        }

        x := x * device.controlWidth / device.standard.controlWidth
        if (absoluteCoordinate) {
            x += device.xBorder[1]
        }
        x := Round(x)
        return x
    }

    y(y, absoluteCoordinate := true) {
        if (absoluteCoordinate) {
            y -= device.standard.yBorder[1]
        }
        y := y * device.controlHeight / device.standard.controlHeight
        if (absoluteCoordinate) {
            y += device.yBorder[1]
        }
        y := Round(y)
        return y
    }

    mag(xy) {
        return [
            x(xy[1], false),
            y(xy[2], false)
        ]
    }

    xy(xy) {
        return [
            x(xy[1]),
            y(xy[2])
        ]
    }
}