
runAttack(starTarget) {

    startAttack()

    message "deploy hero", "progress"
    secureClick game.army.hero
    deployCoordinate:=secureDeploy(1)

    if starTarget>0 {
        secureClick game.army.hero
        deployTroops(deployCoordinate)
    }

    starCount := 0
    abilityActivationLimit :=4 ;maximum hero ability activations before surrender (first use 2 charges)
    troopDeployed := false
    loop abilityActivationLimit { 
        abilityActivations := A_Index

        startTime := A_TickCount
        while A_TickCount - startTime <= 14000 {
            message "activations: " abilityActivations "/" abilityActivationLimit " (" A_TickCount - startTime "), current stars: " starCount "/" starTarget, "progress"
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

deployTroops(deployCoordinate,troopCount:=6) {
    message "deploy troops", "progress"
    clickTroop(1)
    secureDeploy(6,deployCoordinate)

    message "activate troop ability", "progress"
    clickTroop(6)

    clickTroop(troopCount) {
        loop troopCount {
            x := game.army.troopX + game.army.troopXinc * (A_Index - 1)
            y := game.army.troopY
            secureClick [x, y], 10
        }
    }    
} 

secureDeploy(times,deployCoordinate:=false) {
    loop times {
        if (deployCoordinate) {
            secureClick deployCoordinate, 10
        } else {
            attempts:=0
            deployCoordinate:=game.deploy.start.Clone()
            deployCoordinate[1]+=correctX(Random(-game.deploy.randomness[1],game.deploy.randomness[1]))
            deployCoordinate[2]+=correctY(Random(-game.deploy.randomness[2],game.deploy.randomness[2]))
            originalCoordinateStr:=strXY(deployCoordinate)

            message "attempting deployment at " deployCoordinate[1] "," deployCoordinate[2], "detail"
            while true {
                secureClick deployCoordinate, 10
                if checkCriteria(game.deploy.surrenderButtonCriteria) {
                    break
                } else {
                    deployCoordinate[1]:=correctX(deployCoordinate[1]+game.deploy.inc[1])
                    deployCoordinate[2]:=correctY(deployCoordinate[2]+game.deploy.inc[2])
                    attempts++
                }
            }
            message Format("troop deployed at {1} after {2} attempts from {3}", 
                originalCoordinateStr,
                attempts,
                strXY(deployCoordinate)
                ), "detail", 10000
        }
    }
    return deployCoordinate

    strXY(xy) {
        return Format("{1},{2}",xy[1],xy[2])
    }
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

unstuck() {
    message "try to unstuck by escape", "progress"
    loop 3 {
        Send "{Escape}"
        sleep 200
    }
    secureClick game.exitDialog.cancel
}