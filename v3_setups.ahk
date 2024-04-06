device := {
    name: "bluestacks",
    screenWidth: 1920,
    screenHeight: 1080,
    xBorder: [1,1],
    yBorder: [49,1],
    windowTitle: "BlueStacks Android 11"
}
device.windowWidth:=device.screenWidth+device.xBorder[1]+device.xBorder[2]
device.windowHeight:=device.screenHeight+device.yBorder[1]+device.yBorder[2]

game := {
    exitDialog: {
        cancel: [750,750]
    },
    elixir: {
        drag: [[900,200],[900,1000]],
        cart: {
            center: [1300,700],
            range: [300,300],
            color: 0xb77e4f
        },
        collect: [1415,960],
        close:{
            center: [1610,155],
            range: [20,20],
            color: 0xE12025
        }
    },

    attack: {
        button: [125,1000],
        start: [1430,750],
        cancel: [950,1000],
        enemyBaseCriteria: {
            center: [390,950],
            range: [30,10],
            color: 0xBB3CEE
        },
        attackButtonCriteria: {
            center: [50,980],
            range: [10,10],
            color: 0xDB8C30
        },
        starCriterias: generateStarCriterias(),
    },

    surrender: {
        button: [135,800],
        okay: [1170,750],
        returnHome: [960,960],
        battleEndCriteria: {
            center:[961,938], ;y level is critical
            range: [100,3],
            color: 0xB3DB85
        }
    },

    army: {
        hero: [195,1000],
        troopX: 365,
        troopXinc: 150,
        troopY: 1050
    },

    deploy: [
        [35,700],
        [300,200]
    ]
}

generateStarCriterias() {
    r:=[]
    x1:=1630
    y:=860
    xInc:=53
    colorA:=0xDD962C ;Yellow
    colorB:=0XAED0E3 ;Silver

    loop 6 {
        r.push {
            center: [x1 + Mod(A_Index-1,3)*xInc,y],
            range: [3,3],
            color: A_Index<4 ? colorA : colorB
        }
    }
    return r
}



setScaleFactor() {
    WinGetClientPos &X, &Y, &W, &H, device.windowName
    windowX:=W-device.xBorder[1]-device.xBorder[2]
    windowY:=H-device.yBorder[1]-device.yBorder[2]
    windowAR:=windowX/windowY
    fx:= windowX/device.screenX
    fy:= windowY/device.screenY
    scaleFactor:=(fx+fy)/2
    ef:=Abs(fx/fy-1)
    ;MsgBox scaleFactor "`n" W "," H "`n" fx "," fy "`n" windowAR "`n" ef
    if(ef)>0.01 {
        MsgBox "Scale Factor Wrong"
        ExitApp
    }
    return scaleFactor
}