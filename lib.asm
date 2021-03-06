;============================
;           Basic
;============================
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
;            File
;============================

createFile PROC
    ; Filename: DS:DX
        PUSH CX
        MOV AH, 3Ch
        MOV CX, 0 ; Doesn't set any special attributes
        INT 21h
    ; Error: CF
    ; Returns handle: AX
        POP CX
createFile ENDP

openFile PROC
    ; Filename: DS:DX
        MOV AX, 3D02h ; Opens file in read/write mode
        INT 21h
    ; Error: CF
    ; Returns handle: AX
        RET
openFile ENDP

closeFile PROC
    ; Handle: BX
        PUSH AX
        MOV AH, 3Eh
        INT 21h
    ; Returns error: CF
        POP AX
        RET
closeFile ENDP

readFile PROC
    ; Handle: BX
    ; Buffer: DS:DX
    ; Length: CX
        PUSH AX
        MOV AH, 3Fh
        INT 21h
    ; Error: CF
    ; Returns
        POP AX
        RET
readFile ENDP

writeFile PROC
    ; Handle: BX
    ; Buffer: DS:DX
    ; Length: CX
        PUSH AX
        MOV AH, 40h
        INT 21h
    ; Error: CF
    ; Returns
        POP AX
        RET
writeFile ENDP

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
        LOCAL @@nextDigit
    ; Inspired by: https://www.geeksforgeeks.org/8086-program-to-print-a-16-bit-decimal-number
        PUSH AX BX CX DX BP ES number
        PUSH DS
        POP ES
        MOV AX, number
        MOV DH, row
        MOV DL, column
    @@nextDigit:
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
        JNE @@nextDigit
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

playSound PROC
        ; Inspired by: http://muruganad.com/8086/8086-assembly-language-program-to-play-sound-using-pc-speaker.html
        ; Sound offset: BX
        ; Sound length: CX
        PUSH AX BX CX
        ; Prepares speakers
        MOV AL, 182
        OUT 43h, AL
    @@note:
        ; Sets frequency number
        MOV AX, [BX]
        OUT 42h, AL
        MOV AL, AH
        OUT 42h, AL
        ; Turns sound on
        IN AL, 61h
        OR AL, 00000011b
        OUT 61h, AL
        ; Pause
        ADD BX, 4
        CALL sleep
        ; Turns sound off
        IN AL, 61h
        AND AL, 11111100b
        OUT 61h, AL
        ADD BX, 4
        SUB CX, 8
        JNE @@note
        POP CX BX AX
        RET
playSound ENDP
