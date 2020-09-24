.MODEL Small
.STACK 100h
.DATA
    INCLUDE text.asm
    INCLUDE types.asm
    INCLUDE config.asm

    ;============================
    ;            Snake
    ;============================
    snakeLength DW 1
    snake POSITION ((graphicWidth/snakeWidth)*(graphicHeight/snakeWidth)) DUP ({})
    snakeDirection DW 0

    ;============================
    ;            Food
    ;============================
    food POSITION <320, 175>
         POSITION <320, 300>

    ;============================
    ;           Score
    ;============================
    score DW 0
        m DW 1111h
        n DW 2222h

.CODE
    INCLUDE lib.asm

    LOCALS ; Enables local symbols

    ;============================
    ;      Game subroutines
    ;============================
    prepareNewGame PROC
            PUSH AX DX
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
            MOV BX, snakeGrowInterval
            POP DX AX
            RET
    prepareNewGame ENDP

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

    snakeHeadIndex PROC
            PUSH DX
            MOV AX, positionOffset
            MUL snakeLength
            SUB AX, positionOffset
            POP DX
            RET
    snakeHeadIndex ENDP

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
        ; Checks border collisions
            CMP CX, borderWidth
            JL @@collisionDetected
            CMP CX, graphicWidth - borderWidth
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

    feedSnake PROC
        ; Input & Return: BX
            PUSH AX CX DX
            DEC BX
            CMP BX, 0
            JNE @@exit
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
        ; Resets interval
            MOV BX, snakeGrowInterval
        @@exit:
            POP DX CX AX
            RET
    feedSnake ENDP

    ;============================
    ;          Screens
    ;============================
    GameScreen PROC
            PUSH AX BX
            setVideoMode graphicMode
            CALL prepareNewGame
            CALL drawBorder
            writeText 1, 2, textColor, scoreLabel, scoreLabelLength
        @@run:
            writeNumber 1, 77, scoreColor, score
            CALL moveAndDrawSnake
            CALL collisionCheck
            CMP AX, 1
            JE @@exitGame
            CALL feedSnake
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
            POP BX AX
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
    END main
