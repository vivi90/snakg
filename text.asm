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

firstPlaceLabel DB "1st:"
firstPlaceLabelLength = $ - firstPlaceLabel

secondPlaceLabel DB "2nd:"
secondPlaceLabelLength = $ - secondPlaceLabel

thirdPlaceLabel DB "3rd:"
thirdPlaceLabelLength = $ - thirdPlaceLabel

scoreLabel DB "Credits"
scoreLabelLength = $ - scoreLabel

gameScoreLabel DB "Score: "
gameScoreLabelLength = $ - gameScoreLabel

gameOver DB "Game Over!"
gameOverLength = $ - gameOver

credits DB "2020 by Vivien Richter, v2.0.0, MIT License"
creditsLength = $ - credits
