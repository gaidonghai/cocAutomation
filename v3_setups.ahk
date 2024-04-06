device := {
    name: "bluestacks",
    screenWidth: 1920,
    screenHeight: 1080,
    xBorder: [1, 1],
    yBorder: [49, 1],
    window: "BlueStacks Android 11",
    control: "BlueStacksApp1"
}

generateGameObject(xBorder := device.xBorder, yBorder := device.yBorder) {
    return {
        exitDialog: {
            cancel: xy([750, 750])
        },
        elixir: {
            drag: [xy([900, 200]), xy([900, 1000])],
            cart: {
                center: xy([1300, 700]),
                range: [300, 300],
                color: 0xb77e4f
            },
            collect: xy([1415, 960]),
            close: {
                center: xy([1610, 155]),
                range: [20, 20],
                color: 0xE12025
            }
        },
        attack: {
            button: xy([125, 1000]),
            start: xy([1430, 750]),
            cancel: xy([950, 1000]),
            enemyBaseCriteria: {
                center: xy([390, 950]),
                range: [30, 10],
                color: 0xBB3CEE
            },
            attackButtonCriteria: {
                center: xy([50, 980]),
                range: [10, 10],
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
                range: [100, 3],
                color: 0xB3DB85
            }
        },
        army: {
            hero: xy([195, 1000]),
            troopX: x(365),
            troopXinc: 150,
            troopY: y(1050)
        },
        deploy: [
            xy([35, 700]),
            xy([300, 200])
        ]
    }

    generateStarCriterias() {
        r := []
        x1 := 1630
        y1 := 860
        xInc := 53
        colorA := 0xDD962C ;Yellow
        colorB := 0XAED0E3 ;Silver

        loop 6 {
            r.push {
                center: xy([x1 + Mod(A_Index - 1, 3) * xInc, y1]),
                range: [5, 5],
                color: A_Index < 4 ? colorA : colorB
            }
        }
        return r
    }

    x(x) {
        return x - device.xBorder[1] + xBorder[1]
    }
    y(y) {
        return y - device.yBorder[1] + yBorder[1]
    }
    xy(xy) {
        return [
            x(xy[1]),
            y(xy[2])
        ]
    }
}