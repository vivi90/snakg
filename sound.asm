;============================
;          Sounds
;============================
feedSound DD 4063, 100000 ; Note with pause
feedSoundLength = $ - feedSound

gameOverSound DD 4560, 100000, 4304, 50000, 7239, 100000, 9121, 1000000
gameOverSoundLength = $ - gameOverSound
