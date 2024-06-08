
runAttack(starTarget) {

    startAttack()

    starCount := 0
    abilityActivationLimit :=4 ;maximum hero ability activations in each stages 
    loop 2 { 
        ;First loop: 2 stages
        battleStage:=A_Index
        message "deploy hero", "progress"
        secureClick game.army.hero
        deployCoordinate:=secureDeploy()
        if starTarget==0 {
            break
        }
        deployTroops(deployCoordinate,4+A_Index*2)

        startTime := A_TickCount
        nextAbility := startTime
        stageCleared := false
        abilityUsed:=0
        loop {
            ;Second loop: fight within stages
            ;keep fighting until break conditions

            ;Use hero ability
            if A_TickCount>=nextAbility and not stageCleared{
                abilityUsed++
                secureClick game.army.hero
                nextAbility:=A_TickCount+15000
                message Format("ability activations: {1}/{2}",abilityUsed,abilityActivationLimit), "detail"

            }

            if (checkCriteria(game.attack.starCriterias[starCount + 1])) {
                starCount++
                if(starCount==3) {
                    stageCleared:= A_TickCount
                    message "Got 3 stars in stage one, waiting for 2nd stages to appear", "detail"
                }
                message Format("current stars: {1}/{2}", starCount, starTarget), "progress"
            }

            if abilityUsed>abilityActivationLimit || checkCriteria(game.surrender.battleEndCriteria) || starCount >= starTarget {
                break 2 ;quit 2 levels to end this attack
            }

            if stageCleared and A_TickCount>stageCleared+3000 and not checkCriteria(game.attack.starCriterias[3]) {
                sleep 2000
                message "2nd stage ready, deploying troops", "detail"
                break 1 ;quit 1 levels to end this stage
            }
        }
    }

    message "", "progress"
    message "", "detail"
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

deployTroops(deployCoordinate,troopCount:=6) {
    message "deploy troops", "detail"
    loop troopCount{
        clickTroop(A_Index)
        secureDeploy(deployCoordinate)
        clickTroop(A_Index)
    }

    clickTroop(troopNumber) {
        x := game.army.troopX + game.army.troopXinc * (troopNumber - 1)
        y := game.army.troopY
        secureClick [x, y], 10
    } 
} 

secureDeploy(deployCoordinate:=false) {
    if (deployCoordinate) {
        secureClick deployCoordinate, 10
    } else {
        attempts:=0
        deployCoordinate:=game.deploy.start.Clone()
        deployCoordinate[1]+=correctX(Random(-game.deploy.randomness[1],game.deploy.randomness[1]))
        deployCoordinate[2]+=correctY(Random(-game.deploy.randomness[2],game.deploy.randomness[2]))
        originalCoordinateStr:=strXY(deployCoordinate)

        loop 10 {
            secureClick deployCoordinate,0
            sleep 100
            if checkCriteria(game.deploy.countdownTimerCriteria) {
                break
            } else {
                if(A_Index<=4) {
                    deployCoordinate[1]:=correctX(deployCoordinate[1]+game.deploy.inc[1])
                    deployCoordinate[2]:=correctY(deployCoordinate[2]+game.deploy.inc[2])
                } else {
                    deployCoordinate[1]:=correctX(Random(device.xBorder[1],device.controlWidth - device.xBorder[2]))
                    deployCoordinate[2]:=correctY(Random(game.deploy.safeYRange[1],game.deploy.safeYRange[2]))
                }

                attempts++
            }
        }
        message Format("Deployed at {1} after {2} attempts from {3}", strXY(deployCoordinate), attempts,originalCoordinateStr ), "progress"
    }

    return deployCoordinate

    strXY(xy) {
        return Format("{1},{2}",xy[1],xy[2])
    }
}

quitAttack() {
    while true {
        message "checking battle end dialog...", "progress"
        if checkCriteria(game.surrender.battleEndCriteria) {
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
            message "battle end dialog not found, try click buttons", "progress"
            secureClick game.surrender.button
            secureClick game.surrender.okay 
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