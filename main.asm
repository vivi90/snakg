.MODEL Small
.STACK 100h
.DATA
    INCLUDE text.asm
    INCLUDE types.asm
    INCLUDE config.asm

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
    score DW 0

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
            MOV score, 0
            CALL drawBorder
            writeText 1, 2, textColor, scoreLabel, scoreLabelLength
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
        @@next:
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
            JMP @@next
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
        ; Calculates head element index
            CALL snakeHeadIndex
            MOV BX, AX
            ADD BX, OFFSET snake
        ; Loads head element coordinates
            MOV CX, [BX].x
            MOV DX, [BX].y
        ; Resets collision state
            MOV AX, 0
        ; Checks food collision
            CMP CX, [food].x
            JL $ + 20 ; Next x coordinate
            CMP CX, [food].x + foodSize
            JG $ + 14 ; Next x coordinate
            CMP DX, [food].y
            JL $ + 8 ; Next x coordinate
            CMP DX, [food].y + foodSize
            JNG @@foodDetected
            ADD CX, snakeWidth
            CMP CX, [food].x
            JL $ + 20 ; Next x coordinate
            CMP CX, [food].x + foodSize
            JG $ + 14 ; Next x coordinate
            CMP DX, [food].y
            JL $ + 8 ; Next x coordinate
            CMP DX, [food].y + foodSize
            JNG @@foodDetected
            ADD DX, snakeWidth
            CMP CX, [food].x
            JL $ + 20 ; Next x coordinate
            CMP CX, [food].x + foodSize
            JG $ + 14 ; Next x coordinate
            CMP DX, [food].y
            JL $ + 8 ; Next x coordinate
            CMP DX, [food].y + foodSize
            JNG @@foodDetected
            SUB CX, snakeWidth
            CMP CX, [food].x
            JL $ + 20 ; Next x coordinate
            CMP CX, [food].x + foodSize
            JG $ + 14 ; Next x coordinate
            CMP DX, [food].y
            JL $ + 8 ; Next x coordinate
            CMP DX, [food].y + foodSize
            JNG @@foodDetected
            SUB DX, snakeWidth
            JMP @@checkBorderCollision
        ; Feeds the snake
        @@foodDetected:
            drawDot [food].x, [food].y, backgroundColor, foodSize
            CALL feedSnake
            CALL placeFood
            JMP @@exit
        ; Checks border collisions
        @@checkBorderCollision:
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
            ;MOV CX, 12 * snakeWidth + borderWidth
            ;MOV DX, 2 * borderWidth + textHeight + snakeWidth
            MOV [food].x, CX
            MOV [food].y, DX
            drawDot CX, DX, foodColor, foodSize
            POP DX CX BX AX
            RET
    placeFood ENDP

    feedSnake PROC
            PUSH AX BX CX DX
        ; Increases score
            INC score
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

    ;============================
    ;          Screens
    ;============================
    GameScreen PROC
            PUSH AX
            setVideoMode graphicMode
            CALL prepareNewGame
        @@run:
            writeNumber 1, 77, scoreColor, score
            CALL moveAndDrawSnake
            CALL collisionCheck ; Uses also other procedures for feeding the snake and placing new food
            CMP AX, 1
            JE @@exitGame
            sleep snakeDelay
        @@gameInput:
            loadInput
            JE @@run ; checks, if key is pressed
            clearInput
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
            clearInput
            setVideoMode minimalTextMode
            writeText 12, 15, gameOverColor, gameOver, gameOverLength
            sleep gameOverDelay
            POP AX
            RET
    GameScreen ENDP

    MenuScreen PROC
            PUSH AX
        @@menu:
            setVideoMode textMode
            writeText 0, 0, textColor, logo, logoLength
            writeText 12, 8, hintColor, hint, hintLength
            writeText 24, 20, textColor, credits, creditsLength
        @@menuInput:
            loadInput
            JE @@menuInput ; checks, if key is pressed
            clearInput
            CMP AL, CR
            JE @@startNewGame
            CMP AL, Esc
            JE @@exitMenu
            JMP @@menuInput
        @@startNewGame:
            CALL GameScreen
            JMP @@menu
        @@exitMenu:
            setVideoMode textMode ; Clears Screen
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
        MOV BP, 0
        MOV CX, 17
        MOV DX, 17
        CMP CX, 15
        JNG fail
        CMP CX, 15 + 5
        JNL fail
        CMP DX, 15
        JNG fail
        CMP DX, 15 + 5
        JL detected
    fail:
        MOV BP, 1
        JMP exit
    detected:
        MOV BP, 9
    exit:
        NOP
    END main
