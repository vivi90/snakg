;============================
;       Configuration
;============================
minimalTextMode EQU 01h ; 40x25 chars, 16 colors
textMode EQU 03h ; 80x25 chars, 16 colors
graphicMode EQU 10h ; 80x25 chars, 640x350 pixels, 16 colors
graphicWidth EQU 640
graphicHeight EQU 350
textHeight EQU 25
borderWidth EQU 8 ; 8 pixels (max. 256)
snakeWidth EQU 8 ; 8 pixels (max. 256)
foodSize EQU 4 ; 2x2 pixels (max. 256x256)
backgroundColor EQU black
textColor EQU white
hintColor EQU whiteblink
borderColor EQU darkgray
snakeBodyColor EQU blue
snakeHeadColor EQU green
foodColor EQU yellow
scoreColor EQU yellow
gameOverColor EQU red
defaultSnakeLength EQU 8
defaultSnakeDirection EQU right
snakeDelay DD 100000 ; 100ms
;snakeDelay DD 1000000 ; 1s
gameOverDelay DD 2000000 ; 1s
