;============================
;           Texts
;============================
logo DB "                  ****                                     ", 13, 10
     DB "                 *                                         ", 13, 10
     DB "                *                            *             ", 13, 10
     DB "                *                            *             ", 13, 10
     DB "                 *                   ****    *         ****", 13, 10
     DB "                  *                     *   *   *    *    *", 13, 10
     DB "                   *      ***       *****   *  *    *     *", 13, 10
     DB "                    *    *   *     *    *   ***      *    *", 13, 10
     DB "                    *   *     *   *     *   *  *      *****", 13, 10
     DB "                   *    *     *    *    *   *   *         *", 13, 10
     DB "                ***     *     *     ****    *    *    **** ", 13, 10
logoLength = $ - logo
hint DB "Please press [ENTER] to start a new game or [ESC] to exit.", 13, 10
hintLength = $ - hint
scoreLabel DB "Score: "
scoreLabelLength = $ - scoreLabel
gameOver DB "Game Over!"
gameOverLength = $ - gameOver
credits DB "2020 by Vivien Richter, MIT License"
creditsLength = $ - credits
