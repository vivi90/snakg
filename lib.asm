;============================
;           Basic
;============================
stackFrame EQU 8 ; Space for stored AX, BX, CX, and DX register

sleep PROC
    ; Time: BX = OFFSET
        PUSH AX CX DX
        MOV AH, 86h
        MOV DX, [BX] ; Lower us
        MOV CX, [BX + 2h] ; Upper us
        INT 15h
        POP DX CX AX
        RET
sleep ENDP

randomNumber PROC
    ; Inspired by: https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly
        PUSH DX CX BX AX
    ; Range: AX to BX
        SUB BX, AX
    ; Gets current system time
        MOV AH, 2Ch
        INT 21h
    ; Keeps seconds and hundredths of seconds as seed
        MOV AX, DX
        MOV DX, 0
    ; Uses modulo to get a pseudo-random number
        MOV CX, BX
        DIV CX
    ; Considers range
        POP AX
        ADD DX, AX
    ; Returns random number: AX
        MOV AX, DX
        POP BX CX DX
        RET
randomNumber ENDP

;============================
;           Input
;============================
loadInput PROC
    ; Return: AL
        MOV AH, 01h ; Without waiting
        INT 16h
        RET
loadInput ENDP

clearInput PROC
        PUSH AX
        MOV AH, 0Ch
        MOV AL, 0h
        INT 21h
        POP AX
        RET
clearInput ENDP

;============================
;          Output
;============================
setVideoMode PROC
    ; Mode: AL
        MOV AH, 0h
        INT 10h
        RET
setVideoMode ENDP

getPixelColor PROC
    ; x: CX
    ; y: DX
        PUSH BX
        MOV AH, 0Dh
        MOV BH, 0 ; Page: 0
        INT 10h
    ; Returns color: AL
        POP BX
        RET
getPixelColor ENDP

writeText MACRO row, column, style, text, length
        PUSH AX BX CX DX BP ES
        MOV DL, column
        MOV DH, row
        MOV BL, style
        MOV BP, OFFSET text
        MOV CX, length
        MOV AH, 13h
        MOV AL, 01h ; Attributes in BL & updates cursor position
        MOV BH, 0 ; Page
        PUSH DS
        POP ES
        INT 10h
        POP ES BP DX CX BX AX
ENDM

writeNumber MACRO row, column, style, number
    ; Inspired by: https://www.geeksforgeeks.org/8086-program-to-print-a-16-bit-decimal-number
        PUSH AX BX CX DX BP ES number
        PUSH DS
        POP ES
        MOV AX, number
        MOV DH, row
        MOV DL, column
    @@next:
        MOV BX, 10 ; Decimal divisor
        PUSH DX
        MOV DX, 0 ; Reset remainder
        DIV BX
        MOV number, DX ; Uses remainder directly
        POP DX
        PUSH AX
        ADD number, 48 ; ASCII digit offset
        MOV BP, OFFSET number
        MOV CX, 1 ; Length
        MOV AH, 13h
        MOV AL, 01h ; Attributes in BL & updates cursor position
        MOV BH, 0 ; Page
        MOV BL, style
        INT 10h
        DEC DX
        POP AX
        CMP AX, 0
        JNE @@next
        POP number ES BP DX CX BX AX
ENDM

drawDot MACRO x, y, color, size
        LOCAL @@xPixel, @@yPixel
        PUSH AX BX CX DX BP
        MOV AX, 0C00h + color
        MOV BX, size ; Page: 0
        MOV CX, x
        MOV DX, y
        PUSH DX
        MOV BP, SP
    @@xPixel:
        PUSH BX
        MOV BL, size
        MOV DX, [BP]
        @@yPixel:
            INT 10h
            INC DX
            DEC BL
            JNZ @@yPixel
        POP BX
        INC CX
        DEC BL
        JNZ @@xPixel
        POP DX BP DX CX BX AX
ENDM

drawHorizontalLine MACRO y, color, size
        LOCAL @@next, @@draw
        PUSH CX
        MOV CX, graphicWidth
    @@next:
        SUB CX, size
        JNS @@draw
        MOV CX, 0
        @@draw:
            drawDot CX, y, color, size
            CMP CX, 0
        JNE @@next
        POP CX
ENDM

drawVerticalLine MACRO x, color, size
        LOCAL @@next, @@draw
        PUSH DX
        MOV DX, graphicHeight
    @@next:
        SUB DX, size
        JNS @@draw
        MOV DX, 0
        @@draw:
            drawDot x, DX, color, size
            CMP DX, 0
        JNE @@next
        POP DX
ENDM
