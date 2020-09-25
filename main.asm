.MODEL Small
.STACK 100h
.DATA
    INCLUDE text.asm
    INCLUDE types.asm
    INCLUDE config.asm

    buffer DW ? ; Multipurpose buffer for working with temporary data

    ;============================
    ;            Snake
    ;============================
    snakeLength DW defaultSnakeLength
    snake POSITION ((graphicWidth/snakeWidth)*(graphicHeight/snakeWidth)) DUP ({})
    snakeDirection DIRECTION defaultSnakeDirection

    ;============================
    ;            Food
    ;============================
    food POSITION {}

    ;============================
    ;           Score
    ;============================
    currentScore DW 0 ; Maximum: 65535; Real maximum: 3500
    highscore DW 1000, 500, 100 ; Initial highscore, if none exists

.CODE
    INCLUDE lib.asm

    LOCALS ; Enables local symbols

    ;============================
    ;      Game subroutines
    ;============================
    prepareNewGame PROC
            PUSH AX BX DX
            MOV snakeLength, 0
            MOV BX, 0
        @@createSnake:
            MOV AX, snakeWidth
            MUL snakeLength
            ADD AX, borderWidth
            MOV [snake + BX].x, AX
            MOV [snake + BX].y, 2 * borderWidth + textHeight + snakeWidth
            ADD BX, positionOffset
            INC snakeLength
            CMP snakeLength, defaultSnakeLength
            JNE @@createSnake
            MOV snakeDirection, defaultSnakeDirection
            MOV currentScore, 0
            CALL drawBorder
            writeText 1, 2, textColor, gameScoreLabel, gameScoreLabelLength
            CALL placeFood
            POP DX BX AX
            RET
    prepareNewGame ENDP

    snakeHeadIndex PROC
            PUSH DX
            MOV AX, positionOffset
            MUL snakeLength
            SUB AX, positionOffset
            POP DX
        ; Returns index: AX
            RET
    snakeHeadIndex ENDP

    drawBorder PROC
            PUSH CX DX
            MOV CX, 0
            drawVerticalLine CX, borderColor, borderWidth
            MOV DX, 0
            drawHorizontalLine DX, borderColor, borderWidth
            MOV DX, borderWidth + textHeight
            drawHorizontalLine DX, borderColor, borderWidth
            MOV DX, graphicHeight - borderWidth
            drawHorizontalLine DX, borderColor, borderWidth
            MOV CX, graphicWidth - borderWidth
            drawVerticalLine CX, borderColor, borderWidth
            POP DX CX
            RET
    drawBorder ENDP

    moveAndDrawSnake PROC
            PUSH AX BX CX DX
        ; Repaints old tail to hide it
            drawDot snake.x, snake.y, backgroundColor, snakeWidth
            MOV BX, 0
        @@nextPart:
            ; Checks, if it's the last element
            CALL snakeHeadIndex
            CMP BX, AX
            JE @@head
            ; Loads the next element
            MOV CX, [snake + BX + positionOffset].x
            MOV DX, [snake + BX + positionOffset].y
            ; Updates current element
            MOV [snake + BX].x, CX
            MOV [snake + BX].y, DX
        @@drawBody:
            ; Draws loaded element as body part
            drawDot CX, DX, snakeBodyColor, snakeWidth
            ; Increments the pointer
            ADD BX, positionOffset
            JMP @@nextPart
        @@head:
            ; Loads the current element
            MOV CX, [snake + BX].x
            MOV DX, [snake + BX].y
            CMP snakeDirection, up
            JE @@goUp
            CMP snakeDirection, left
            JE @@goLeft
            CMP snakeDirection, down
            JE @@goDown
            ADD CX, snakeWidth
            JMP @@drawHead
        @@goUp:
            SUB DX, snakeWidth
            JMP @@drawHead
        @@goLeft:
            SUB CX, snakeWidth
            JMP @@drawHead
        @@goDown:
            ADD DX, snakeWidth
        @@drawHead:
            ; Updates current element
            MOV [snake + BX].x, CX
            MOV [snake + BX].y, DX
            ; Draws updated element as head
            drawDot CX, DX, snakeHeadColor, snakeWidth
            POP DX CX BX AX
            RET
    moveAndDrawSnake ENDP

    collisionCheck PROC
            PUSH BX CX DX
        ; Checks food collision
            MOV CX, [food].x
            MOV DX, [food].y
            CALL getPixelColor
            CMP AL, snakeHeadColor
            JE @@foodDetected
            ADD CX, foodSize
            CALL getPixelColor
            CMP AL, snakeHeadColor
            JE @@foodDetected
            ADD DX, foodSize
            CALL getPixelColor
            CMP AL, snakeHeadColor
            JE @@foodDetected
            SUB CX, foodSize
            CALL getPixelColor
            CMP AL, snakeHeadColor
            JE @@foodDetected
            SUB DX, foodSize
        ; Calculates head element index
            CALL snakeHeadIndex
            MOV BX, AX
            ADD BX, OFFSET snake
        ; Loads head element coordinates
            MOV CX, [BX].x
            MOV DX, [BX].y
        ; Checks border collisions
        @@checkBorderCollision:
            MOV AX, 0 ; Resets collision state at first
            CMP CX, borderWidth
            JL @@collisionDetected
            CMP CX, graphicWidth - borderWidth - snakeWidth
            JG @@collisionDetected
            CMP DX, 2 * borderWidth + textHeight
            JL @@collisionDetected
            CMP DX, graphicHeight - borderWidth - snakeWidth
            JG @@collisionDetected
        ; Checks self collisions
        @@nextElement:
            SUB BX, positionOffset
            CMP CX, [BX].x
            JNE $ + 7
            CMP DX, [BX].y
            JE @@collisionDetected
            CMP BX, OFFSET snake
            JE @@exit
            JMP @@nextElement
        ; Returns: AX = 1 if collision detected, otherwise 0
        @@exit:
            POP DX CX BX
            RET
        ; Changes collision state
        @@collisionDetected:
            MOV AX, 1
            JMP @@exit
        ; Feeds the snake
        @@foodDetected:
            drawDot [food].x, [food].y, backgroundColor, foodSize
            CALL feedSnake
            CALL placeFood
            JMP @@exit
    collisionCheck ENDP

    placeFood PROC
            PUSH AX BX CX DX
        @@randomCoordinates:
        ; Gets random x coordinate
            MOV AX, borderWidth
            MOV BX, graphicWidth - borderWidth
            CALL randomNumber
            MOV CX, AX
        ; Gets random y coordinate
            MOV AX, 2 * borderWidth + textHeight
            MOV BX, graphicHeight - borderWidth - snakeWidth
            CALL randomNumber
            MOV DX, AX
        ; Iterates over all snake parts to check collision
            MOV BX, OFFSET snake
            CALL snakeHeadIndex
            ADD BX, AX
        @@nextCheck:
            CMP CX, [BX].x
            JNE $ + 7
            CMP DX, [BX].y
            JE @@randomCoordinates
            CMP BX, OFFSET snake
            JE @@place
            SUB BX, positionOffset
            JMP @@nextCheck
        @@place:
            MOV [food].x, CX
            MOV [food].y, DX
            drawDot CX, DX, foodColor, foodSize
            POP DX CX BX AX
            RET
    placeFood ENDP

    feedSnake PROC
            PUSH AX BX CX DX
        ; Increases score
            INC currentScore
        ; Increases snake length
            CALL snakeHeadIndex
            MOV BX, AX
            MOV CX, [snake + BX].x
            MOV DX, [snake + BX].y
            CMP snakeDirection, up
            JE @@goUp
            CMP snakeDirection, left
            JE @@goLeft
            CMP snakeDirection, down
            JE @@goDown
            ADD CX, snakeWidth
            JMP @@grow
        @@goUp:
            SUB DX, snakeWidth
            JMP @@grow
        @@goLeft:
            SUB CX, snakeWidth
            JMP @@grow
        @@goDown:
            ADD DX, snakeWidth
        @@grow:
            MOV [snake + BX + positionOffset].x, CX
            MOV [snake + BX + positionOffset].y, DX
            INC snakeLength
        @@exit:
            POP DX CX BX AX
            RET
    feedSnake ENDP

    updateHighscore PROC
            PUSH AX BX CX
            MOV BX, currentScore
        @@checkFirstPlace:
            MOV AX, highscore
            CMP AX, BX
            JG @@checkSecondPlace
            MOV CX, [DS:(OFFSET highscore + 2)] ; Old second place
            MOV [DS:(OFFSET highscore + 4)], CX ; Becomes new third place
            MOV [DS:(OFFSET highscore + 2)], AX ; Old first place becomes new second place
            MOV highscore, BX ; New first place
            JMP @@exit
        @@checkSecondPlace:
            MOV AX, [DS:(OFFSET highscore + 2)]
            CMP AX, BX
            JG @@checkThirdPlace
            MOV [DS:(OFFSET highscore + 4)], AX ; Old second place becomes new third place
            MOV [DS:(OFFSET highscore + 2)], BX ; New second place
            JMP @@exit
        @@checkThirdPlace:
            MOV AX, [DS:(OFFSET highscore + 4)]
            CMP AX, BX
            JG @@exit
            MOV [DS:(OFFSET highscore + 4)], BX ; New third place
        @@exit:
            POP CX BX AX
            RET
    updateHighscore ENDP

    ;============================
    ;      Menu subroutines
    ;============================
    loadHighscore PROC
            PUSH AX BX CX DX
            LEA DX, highscoreFile
            CALL openFile
            JC @@return ; If file not found
            MOV BX, AX ; Handle
            MOV CX, 2 ; Byte length of each value
            LEA DX, highscore
            CALL readFile
            LEA DX, [DS:(OFFSET highscore + 2)]
            CALL readFile
            LEA DX, [DS:(OFFSET highscore + 4)]
            CALL readFile
            CALL closeFile
        @@return:
            POP DX CX BX AX
            RET
    loadHighscore ENDP

    saveHighscore PROC
            PUSH AX BX CX DX
            LEA DX, highscoreFile
            CALL createFile
            MOV BX, AX ; Handle
            MOV CX, 2 ; Byte length of each value
            LEA DX, highscore
            CALL writeFile
            LEA DX, [DS:(OFFSET highscore + 2)]
            CALL writeFile
            LEA DX, [DS:(OFFSET highscore + 4)]
            CALL writeFile
            CALL closeFile
            POP DX CX BX AX
            RET
    saveHighscore ENDP

    showHighscore PROC
            PUSH AX
        @@firstPlace:
            writeText 16, 25, highscoreColor, firstPlaceLabel, firstPlaceLabelLength
            MOV AX, highscore
            writeNumber 16, 40, highscoreColor, highscore
            writeText 16, 43, highscoreColor, scoreLabel, scoreLabelLength
            CMP AX, currentScore
            JNE @@secondPlace
            writeNumber 16, 40, ownHighscoreColor, highscore
        @@secondPlace:
            writeText 18, 25, highscoreColor, secondPlaceLabel, secondPlaceLabelLength
            MOV AX, [DS:(OFFSET highscore + 2)]
            MOV buffer, AX
            writeNumber 18, 40, highscoreColor, buffer
            writeText 18, 43, highscoreColor, scoreLabel, scoreLabelLength
            CMP AX, currentScore
            JNE @@thirdPlace
            writeNumber 18, 40, ownHighscoreColor, buffer
        @@thirdPlace:
            writeText 20, 25, highscoreColor, thirdPlaceLabel, thirdPlaceLabelLength
            MOV AX, [DS:(OFFSET highscore + 4)]
            MOV buffer, AX
            writeNumber 20, 40, highscoreColor, buffer
            writeText 20, 43, highscoreColor, scoreLabel, scoreLabelLength
            CMP AX, currentScore
            JNE @@return
            writeNumber 20, 40, ownHighscoreColor, buffer
        @@return:
            POP AX
            RET
    showHighscore ENDP

    ;============================
    ;          Screens
    ;============================
    GameScreen PROC
            PUSH AX BX
            MOV AL, graphicMode
            CALL setVideoMode
            MOV AL, 0
            CALL prepareNewGame
        @@run:
            writeNumber 1, 77, scoreColor, currentScore
            CALL moveAndDrawSnake
            CALL collisionCheck ; Uses also other procedures for feeding the snake and placing new food
            CMP AX, 1
            JE @@exitGame
            MOV BX, OFFSET snakeDelay
            CALL sleep
        @@gameInput:
            CALL loadInput
            JE @@run ; checks, if key is pressed
            CALL clearInput
            CMP AL, w
            JE @@goUp
            CMP AL, a
            JE @@goLeft
            CMP AL, s
            JE @@goDown
            CMP AL, d
            JE @@goRight
            CMP AL, Esc
            JE @@exitGame
            JMP @@run
        @@goUp:
            CMP snakeDirection, down
            JE @@wrongDirection
            MOV snakeDirection, up
            JMP @@run
        @@goLeft:
            CMP snakeDirection, right
            JE @@wrongDirection
            MOV snakeDirection, left
            JMP @@run
        @@goDown:
            CMP snakeDirection, up
            JE @@wrongDirection
            MOV snakeDirection, down
            JMP @@run
        @@goRight:
            CMP snakeDirection, left
            JE @@wrongDirection
            MOV snakeDirection, right
        @@wrongDirection:
            JMP @@run
        @@exitGame:
            CALL updateHighscore
            MOV AL, minimalTextMode
            CALL setVideoMode
            writeText 12, 15, gameOverColor, gameOver, gameOverLength
            MOV BX, OFFSET gameOverDelay
            CALL sleep
            POP BX AX
            RET
    GameScreen ENDP

    MenuScreen PROC
            PUSH AX
            CALL loadHighscore
        @@menu:
            MOV AL, textMode
            CALL setVideoMode
            writeText 0, 0, textColor, logo, logoLength
            writeText 12, 8, hintColor, hint, hintLength
            CALL showHighscore
            writeText 24, 20, textColor, credits, creditsLength
        @@menuInput:
            CALL loadInput
            JE @@menuInput ; checks, if key is pressed
            CALL clearInput
            CMP AL, CR
            JE @@startNewGame
            CMP AL, Esc
            JE @@exitMenu
            JMP @@menuInput
        @@startNewGame:
            CALL GameScreen
            JMP @@menu
        @@exitMenu:
            CALL saveHighscore
            MOV AL, textMode
            CALL setVideoMode ; Clears Screen
            POP AX
            RET
    MenuScreen ENDP

    ;============================
    ;        Entry point
    ;============================
    main:
        STARTUPCODE
        CALL MenuScreen
        EXITCODE
    END main
