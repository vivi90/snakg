;============================
;          Colors
;============================
COLOR ENUM black, blue, green, cyan, red, magenta, brown, lightgray, darkgray, lightblue, lightgreen, lightcyan, lightred, lightmagenta, yellow, white, redblink = 132, whiteblink = 143

;============================
;           Keys
;============================
KEY ENUM CR = 13, Esc = 27, a = 97, d = 100, s = 115, w = 119

;============================
;         Position
;============================
POSITION STRUC
    x DW 0
    y DW 0
POSITION ENDS
positionOffset EQU 4

;============================
;        Directions
;============================
DIRECTION ENUM up, left, down, right
