;ATARI BREAKOUT GAME 
;Developed by Nawab Ikram as a semester project of Computer Organization and Assembley Language 




[org 0x0100]

jmp start

; Game variables
score: dw 0
lives: db 3
ballX: dw 40
ballY: dw 12
ballDirX: db 1
ballDirY: db 1
paddleX: db 32
paddleWidth: db 12
gameActive: db 0
totalBricks: dw 32
bricksRemaining: dw 32
gameSpeed: db 4
level: db 1
maxLevel: db 3
selectedLevel: db 1
levelSelectActive: db 0

; Arrays
bricks: times 32 db 1
brickColors: db 0x4C, 0x4E, 0x4A, 0x4B
brickPoints: dw 40, 30, 20, 10

; Movement variables
leftSpeedCounter: db 0
rightSpeedCounter: db 0
paddleTimer: db 0
paddleAcceleration: db 1
ballSpeedCounter: db 0
ballSpeedDelay: db 3

; File handling
highFileName: db 'HIGHSCR.DAT',0
backupFileName: db 'HIGHBAK.DAT',0
highScoreBuf: dw 0
fileBuffer: times 10 db 0

; Sound variables
soundDuration: dw 0
soundFreq: dw 0
multiSoundCounter: db 0

; Messages
welcomeMsg: db '*** ATARI BREAKOUT GAME ***', 0
developedByMsg: db 'Developed by: Nawab Ikram & Abdulwahab', 0
rulesTitle: db 'RULES:', 0
rule1: db 'LEFT/RIGHT arrows = Move paddle', 0
rule2: db 'Break all bricks to win!', 0
rule3: db 'You have 3 lives', 0
rule4: db 'Each brick = points by color', 0
rule5: db 'Dont let ball fall!', 0
rule6: db 'NEW: Progressive difficulty levels!', 0
rule7: db 'Press L for Level Selection', 0
startMsg: db 'Press ENTER to Start', 0
exitMsg: db 'Press ESC to Exit', 0

; Level selection messages
levelSelectMsg: db 'SELECT STARTING LEVEL (1-3):', 0
currentLevelMsg: db 'LEVEL: ', 0
confirmMsg: db 'Press ENTER to confirm', 0
upDownMsg: db 'UP/DOWN arrows to change', 0

; Game status messages
scoreLabel: db 'SCORE: ', 0
livesLabel: db 'LIVES: ', 0
highscoreLabel: db 'HIGH: ', 0
levelLabel: db 'LV:', 0
gameOverMsg: db '*** GAME OVER ***', 0
winMsg: db '*** YOU WIN! ***', 0
finalScoreMsg: db 'FINAL SCORE: ', 0
playAgainMsg: db 'ENTER=Play Again | ESC=Exit', 0
newHighMsg: db 'NEW HIGH SCORE!', 0
saveErrorMsg: db 'Error saving high score!', 0
levelUpMsg: db '*** LEVEL UP! ***', 0

; Keyboard handling
oldKbdISR: dd 0
keyPressed: db 0
leftKey: db 0
rightKey: db 0
isNewHigh: db 0
currentRow: db 0

start:
    mov ax, 0x0003
    int 0x10
    call showWelcome
    call waitForStart
    cmp al, 27
    je exitProgram
    cmp al, 'l'
    je showLevelSelection
    cmp al, 'L'
    je showLevelSelection
    jmp mainGameStart

showLevelSelection:
    mov byte [levelSelectActive], 1
    call showLevelSelect
    call handleLevelSelect
    cmp al, 27
    je exitProgram
    jmp mainGameStart

mainGameStart:
    call initGame
    call hookKeyboard

gameLoop:
    cmp byte [gameActive], 0
    je gameEnd
    call movePaddleSmooth
    call movePaddleSmooth
    call delay
    call moveBall
    call drawGame
    cmp byte [keyPressed], 27
    je gameEnd
    jmp gameLoop

gameEnd:
    call unhookKeyboard
    call handleHighScoreEnhanced
    call showGameOver
    call waitForStart
    cmp al, 27
    je exitProgram
    jmp mainGameStart

exitProgram:
    call unhookKeyboard
    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21

; Level selection display
showLevelSelect:
    pusha
    mov ax, 0x0600
    mov bh, 0x00
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Draw level selection box
    mov dh, 8
    mov dl, 20
    call setCursor
    mov ah, 0x09
    mov al, 201
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    ; Top border
    mov dl, 21
    call setCursor
    mov al, 205
    mov cx, 38
    int 0x10
    
    mov dl, 59
    call setCursor
    mov al, 187
    mov cx, 1
    int 0x10
    
    ; Side borders
    mov cx, 6
    mov dh, 9
drawLevelSelectSides:
    push cx
    mov dl, 20
    call setCursor
    mov ah, 0x09
    mov al, 186
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 59
    call setCursor
    int 0x10
    inc dh
    pop cx
    loop drawLevelSelectSides
    
    ; Bottom border
    mov dh, 15
    mov dl, 20
    call setCursor
    mov ah, 0x09
    mov al, 200
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 21
    call setCursor
    mov al, 205
    mov cx, 38
    int 0x10
    
    mov dl, 59
    call setCursor
    mov al, 188
    mov cx, 1
    int 0x10
    
    ; Display messages
    mov dh, 10
    mov dl, 22
    call setCursor
    mov si, levelSelectMsg
    mov bl, 0x0E
    call printStringColor
    
    mov dh, 12
    mov dl, 35
    call setCursor
    mov si, currentLevelMsg
    mov bl, 0x0F
    call printStringColor
    
    ; Display current level
    mov al, [selectedLevel]
    mov ah, 0
    call printNumberWhite
    
    mov dh, 13
    mov dl, 25
    call setCursor
    mov si, upDownMsg
    mov bl, 0x07
    call printStringColor
    
    mov dh, 14
    mov dl, 28
    call setCursor
    mov si, confirmMsg
    mov bl, 0x0A
    call printStringColor
    
    popa
    ret

; Level selection input handler
handleLevelSelect:
    pusha
    
levelSelectLoop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13          ; ENTER key
    je confirmLevel
    cmp ah, 0x48        ; UP arrow
    je increaseLevelSelect
    cmp ah, 0x50        ; DOWN arrow
    je decreaseLevelSelect
    cmp al, 27          ; ESC key
    je exitLevelSelect
    jmp levelSelectLoop
    
increaseLevelSelect:
    mov al, [selectedLevel]
    cmp al, 3
    jge redrawLevelSelect
    inc byte [selectedLevel]
    jmp redrawLevelSelect
    
decreaseLevelSelect:
    mov al, [selectedLevel]
    cmp al, 1
    jle redrawLevelSelect
    dec byte [selectedLevel]
    jmp redrawLevelSelect
    
redrawLevelSelect:
    call showLevelSelect
    jmp levelSelectLoop
    
confirmLevel:
    mov al, [selectedLevel]
    mov [level], al
    mov byte [levelSelectActive], 0
    popa
    ret
    
exitLevelSelect:
    mov byte [levelSelectActive], 0
    popa
    mov al, 27
    ret

; Initialize game
initGame:
    pusha
    mov word [score], 0
    mov byte [lives], 3
    mov word [ballX], 40
    mov word [ballY], 18
    mov byte [ballDirX], 1
    mov byte [ballDirY], -1
    mov byte [paddleX], 32
    mov byte [gameActive], 1
    mov word [bricksRemaining], 32
    call readHighScore
    
    ; Set speed based on selected level
    mov al, [level]
    cmp al, 1
    je setLevel1Speed
    cmp al, 2
    je setLevel2Speed
    jmp setLevel3Speed

setLevel1Speed:
    mov byte [gameSpeed], 4
    mov byte [ballSpeedDelay], 3
    jmp applyLevelSettings

setLevel2Speed:
    mov byte [gameSpeed], 3
    mov byte [ballSpeedDelay], 2
    jmp applyLevelSettings

setLevel3Speed:
    mov byte [gameSpeed], 2
    mov byte [ballSpeedDelay], 1

applyLevelSettings:
    mov byte [leftSpeedCounter], 0
    mov byte [rightSpeedCounter], 0
    mov byte [paddleTimer], 0
    mov byte [paddleAcceleration], 1
    mov byte [ballSpeedCounter], 0
    
    ; Reset bricks
    mov cx, 32
    mov di, bricks
resetBricksLoop:
    mov byte [di], 1
    inc di
    loop resetBricksLoop
    
    popa
    ret

; Initialize new level
initLevel:
    pusha
    mov cx, 32
    mov di, bricks
resetLevelBricks:
    mov byte [di], 1
    inc di
    loop resetLevelBricks
    
    mov word [bricksRemaining], 32
    mov word [ballX], 40
    mov word [ballY], 18
    mov byte [paddleX], 32
    
    mov al, [level]
    cmp al, 1
    je setLevel1Speed
    cmp al, 2
    je setLevel2Speed
    jmp setLevel3Speed

showLevelUpMessage:
    pusha
    mov dh, 12
    mov dl, 30
    call setCursor
    mov si, levelUpMsg
    mov bl, 0x4E
    call printStringColor
    
    mov cx, 30
levelUpPauseLoop:
    push cx
    call delay
    pop cx
    loop levelUpPauseLoop
    popa
    ret

; Keyboard interrupt handler
hookKeyboard:
    pusha
    mov ax, 0x3509
    int 0x21
    mov word [oldKbdISR], bx
    mov word [oldKbdISR+2], es
    
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, kbdISR
    mov ax, 0x2509
    int 0x21
    pop ds
    popa
    ret

unhookKeyboard:
    pusha
    cmp word [oldKbdISR], 0
    je unhookDone
    
    push ds
    mov dx, word [oldKbdISR]
    mov ax, word [oldKbdISR+2]
    mov ds, ax
    mov ax, 0x2509
    int 0x21
    pop ds
    mov word [oldKbdISR], 0
unhookDone:
    popa
    ret

kbdISR:
    pusha
    push ds
    mov ax, cs
    mov ds, ax
    
    in al, 0x60
    mov byte [keyPressed], al
    
    cmp al, 0x4B        ; Left arrow pressed
    je setLeftKey
    cmp al, 0xCB        ; Left arrow released
    je clearLeftKey
    cmp al, 0x4D        ; Right arrow pressed
    je setRightKey
    cmp al, 0xCD        ; Right arrow released
    je clearRightKey
    jmp kbdISRDone

setLeftKey:
    mov byte [leftKey], 1
    jmp kbdISRDone
clearLeftKey:
    mov byte [leftKey], 0
    mov byte [leftSpeedCounter], 0
    jmp kbdISRDone
setRightKey:
    mov byte [rightKey], 1
    jmp kbdISRDone
clearRightKey:
    mov byte [rightKey], 0
    mov byte [rightSpeedCounter], 0

kbdISRDone:
    mov al, 0x20
    out 0x20, al
    pop ds
    popa
    iret

; Improved smooth paddle movement
movePaddleSmooth:
    pusha
    
    ; Base movement speed (improved)
    mov bl, 4
    
    cmp byte [leftKey], 1
    jne checkRightPaddle
    
    inc byte [leftSpeedCounter]
    mov al, [leftSpeedCounter]
    
    ; Progressive acceleration
    cmp al, 2
    jl moveLeftPaddle
    mov bl, 6
    cmp al, 4
    jl moveLeftPaddle
    mov bl, 8
    cmp al, 7
    jl moveLeftPaddle
    mov bl, 10
    
moveLeftPaddle:
    mov al, [paddleX]
    sub al, bl
    cmp al, 1
    jl checkRightPaddle
    mov [paddleX], al
    jmp checkRightPaddle

checkRightPaddle:
    cmp byte [rightKey], 1
    jne resetPaddleCounters
    
    inc byte [rightSpeedCounter]
    mov al, [rightSpeedCounter]
    
    ; Progressive acceleration
    mov bl, 4
    cmp al, 2
    jl moveRightPaddle
    mov bl, 6
    cmp al, 4
    jl moveRightPaddle
    mov bl, 8
    cmp al, 7
    jl moveRightPaddle
    mov bl, 10
    
moveRightPaddle:
    mov al, [paddleX]
    add al, bl
    add al, [paddleWidth]
    cmp al, 78
    jg resetPaddleCounters
    mov al, [paddleX]
    add al, bl
    mov [paddleX], al
    jmp paddleMoveDone

resetPaddleCounters:
    cmp byte [leftKey], 0
    jne paddleMoveDone
    cmp byte [rightKey], 0
    jne paddleMoveDone
    mov byte [leftSpeedCounter], 0
    mov byte [rightSpeedCounter], 0

paddleMoveDone:
    popa
    ret

; Ball movement
moveBall:
    pusha
    inc byte [ballSpeedCounter]
    mov al, [ballSpeedCounter]
    cmp al, [ballSpeedDelay]
    jl skipBallMove
    
    mov byte [ballSpeedCounter], 0
    mov al, [ballDirX]
    cbw
    add [ballX], ax
    mov al, [ballDirY]
    cbw
    add [ballY], ax

skipBallMove:
    ; Wall collision
    mov ax, [ballX]
    cmp ax, 1
    jle bounceXWall
    cmp ax, 78
    jge bounceXWall
    jmp checkYCollision

bounceXWall:
    neg byte [ballDirX]
    cmp word [ballX], 1
    jle fixLeftWall
    mov word [ballX], 77
    jmp wallBounceSound
fixLeftWall:
    mov word [ballX], 2
wallBounceSound:
    call playBounceSoundEnhanced

checkYCollision:
    mov ax, [ballY]
    cmp ax, 1
    jle bounceTopWall
    jmp checkPaddleCollision

bounceTopWall:
    neg byte [ballDirY]
    mov word [ballY], 2
    call playBounceSoundEnhanced

checkPaddleCollision:
    mov ax, [ballY]
    cmp ax, 22
    jne checkBrickCollision
    
    mov ax, [ballX]
    mov bl, [paddleX]
    mov bh, 0
    cmp ax, bx
    jl checkBrickCollision
    add bl, [paddleWidth]
    cmp ax, bx
    jge checkBrickCollision
    
    neg byte [ballDirY]
    mov word [ballY], 21
    call playPaddleSoundEnhanced
    jmp checkBottomBoundary

checkBrickCollision:
    mov ax, [ballY]
    cmp ax, 5
    jl checkBottomBoundary
    cmp ax, 8
    jg checkBottomBoundary
    
    sub ax, 5
    mov si, ax
    mov bx, ax
    shl bx, 3
    
    mov ax, [ballX]
    sub ax, 2
    cmp ax, 0
    jl checkBottomBoundary
    
    mov dx, 0
    mov cx, 9
    div cx
    cmp ax, 8
    jge checkBottomBoundary
    
    add bx, ax
    push bx
    mov di, bricks
    add di, bx
    cmp byte [di], 0
    pop bx
    je checkBottomBoundary
    
    ; Destroy brick
    mov di, bricks
    add di, bx
    mov byte [di], 0
    dec word [bricksRemaining]
    
    ; Add score
    mov bx, si
    shl bx, 1
    add bx, brickPoints
    mov ax, [bx]
    add word [score], ax
    
    neg byte [ballDirY]
    call playBrickSoundEnhanced
    
    ; Check level completion
    cmp word [bricksRemaining], 0
    jne checkBottomBoundary
    
    mov al, [level]
    cmp al, [maxLevel]
    jae endGameWin
    
    inc byte [level]
    call initLevel
    call playLevelCompleteSoundEnhanced
    jmp ballMoveDone

endGameWin:
    mov byte [gameActive], 0
    call playWinSoundEnhanced
    jmp ballMoveDone

checkBottomBoundary:
    mov ax, [ballY]
    cmp ax, 23
    jl ballMoveDone
    
    dec byte [lives]
    call playLifeLostSoundEnhanced
    
    ; Reset ball
    mov word [ballX], 40
    mov word [ballY], 18
    mov byte [ballDirX], 1
    mov byte [ballDirY], -1
    mov byte [paddleX], 32
    mov byte [leftSpeedCounter], 0
    mov byte [rightSpeedCounter], 0
    mov byte [ballSpeedCounter], 0
    
    ; Pause
    mov cx, 15
lifeLostPauseLoop:
    push cx
    call delay
    pop cx
    loop lifeLostPauseLoop
    
    cmp byte [lives], 0
    jne ballMoveDone
    mov byte [gameActive], 0

ballMoveDone:
    popa
    ret

; Draw game screen
drawGame:
    pusha
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x00
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Draw score
    mov dh, 0
    mov dl, 1
    call setCursor
    mov si, scoreLabel
printScoreLabelLoop:
    lodsb
    cmp al, 0
    je printScoreValueStart
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    push si
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop si
    jmp printScoreLabelLoop

printScoreValueStart:
    mov ax, [score]
    call printNumberWhite
    
    ; Draw high score
    mov dh, 0
    mov dl, 25
    call setCursor
    mov si, highscoreLabel
printHighLabelLoop:
    lodsb
    cmp al, 0
    je printHighValueStart
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0E
    mov cx, 1
    int 0x10
    push si
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop si
    jmp printHighLabelLoop

printHighValueStart:
    mov ax, [highScoreBuf]
    call printNumberYellow
    
    ; Draw lives
    mov dh, 0
    mov dl, 55
    call setCursor
    mov si, livesLabel
printLivesLabelLoop:
    lodsb
    cmp al, 0
    je printLivesValueStart
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    push si
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop si
    jmp printLivesLabelLoop

printLivesValueStart:
    mov al, [lives]
    mov ah, 0
    call printNumberWhite
    
    ; Draw level
    mov dh, 0
    mov dl, 70
    call setCursor
    mov si, levelLabel
printLevelLabelLoop:
    lodsb
    cmp al, 0
    je printLevelValueStart
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0A
    mov cx, 1
    int 0x10
    push si
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop si
    jmp printLevelLabelLoop

printLevelValueStart:
    mov al, [level]
    mov ah, 0
    call printNumberGreen
    
    ; Draw top border
    mov dh, 2
    mov dl, 0
    call setCursor
    mov ah, 0x09
    mov al, 196
    mov bh, 0
    mov bl, 0x0F
    mov cx, 80
    int 0x10
    
    ; Draw bricks
    mov byte [currentRow], 0
drawBrickRows:
    mov al, [currentRow]
    cmp al, 4
    jge drawBricksDone
    
    mov dh, al
    add dh, 4
    mov al, [currentRow]
    mov bl, 8
    mul bl
    mov si, ax
    mov cx, 8
    mov dl, 2

drawBrickColumns:
    push cx
    push dx
    mov bx, si
    add bx, bricks
    cmp byte [bx], 0
    je skipBrickDraw
    
    call setCursor
    mov al, [currentRow]
    cmp al, 0
    je setBrickColor0
    cmp al, 1
    je setBrickColor1
    cmp al, 2
    je setBrickColor2
    jmp setBrickColor3

setBrickColor0:
    mov bl, 0x44
    jmp drawBrickBlock
setBrickColor1:
    mov bl, 0x66
    jmp drawBrickBlock
setBrickColor2:
    mov bl, 0x22
    jmp drawBrickBlock
setBrickColor3:
    mov bl, 0x33

drawBrickBlock:
    mov ah, 0x09
    mov al, ' '
    mov bh, 0
    push cx
    mov cx, 8
    int 0x10
    pop cx

skipBrickDraw:
    pop dx
    add dl, 9
    inc si
    pop cx
    loop drawBrickColumns
    
    inc byte [currentRow]
    jmp drawBrickRows

drawBricksDone:
    ; Draw paddle
    mov dh, 22
    mov dl, [paddleX]
    call setCursor
    mov ah, 0x09
    mov al, 219
    mov bh, 0
    mov bl, 0x0B
    mov cl, [paddleWidth]
    mov ch, 0
    int 0x10
    
    ; Draw ball
    mov ax, [ballY]
    mov dh, al
    mov ax, [ballX]
    mov dl, al
    call setCursor
    mov ah, 0x09
    mov al, 'O'
    mov bh, 0
    mov bl, 0x0E
    mov cx, 1
    int 0x10
    
    ; Draw bottom border
    mov dh, 23
    mov dl, 0
    call setCursor
    mov cx, 80
    mov ah, 0x09
    mov al, 196
    mov bh, 0
    mov bl, 0x0F
    int 0x10
    
    popa
    ret

; Show welcome screen
showWelcome:
    pusha
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x00
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Draw welcome box
    mov dh, 4
    mov dl, 10
    call setCursor
    mov ah, 0x09
    mov al, 218
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 11
    call setCursor
    mov al, 196
    mov cx, 58
    int 0x10
    
    mov dl, 69
    call setCursor
    mov al, 191
    mov cx, 1
    int 0x10
    
    ; Draw sides
    mov cx, 18
    mov dh, 5
drawWelcomeSides:
    push cx
    mov dl, 10
    call setCursor
    mov ah, 0x09
    mov al, 179
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 69
    call setCursor
    int 0x10
    inc dh
    pop cx
    loop drawWelcomeSides
    
    ; Draw bottom
    mov dh, 23
    mov dl, 10
    call setCursor
    mov ah, 0x09
    mov al, 192
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 11
    call setCursor
    mov al, 196
    mov cx, 58
    int 0x10
    
    mov dl, 69
    call setCursor
    mov al, 217
    mov cx, 1
    int 0x10
    
    ; Display text
    mov dh, 6
    mov dl, 22
    call setCursor
    mov si, welcomeMsg
    mov bl, 0x0E
    call printStringColor
    
    mov dh, 8
    mov dl, 17
    call setCursor
    mov si, developedByMsg
    mov bl, 0x0D
    call printStringColor
    
    mov dh, 10
    mov dl, 37
    call setCursor
    mov si, rulesTitle
    mov bl, 0x0F
    call printStringColor
    
    mov dh, 12
    mov dl, 15
    call setCursor
    mov si, rule1
    mov bl, 0x07
    call printStringColor
    
    mov dh, 13
    mov dl, 19
    call setCursor
    mov si, rule2
    mov bl, 0x07
    call printStringColor
    
    mov dh, 14
    mov dl, 14
    call setCursor
    mov si, rule3
    mov bl, 0x07
    call printStringColor
    
    mov dh, 15
    mov dl, 22
    call setCursor
    mov si, rule4
    mov bl, 0x07
    call printStringColor
    
    mov dh, 16
    mov dl, 12
    call setCursor
    mov si, rule5
    mov bl, 0x07
    call printStringColor
    
    mov dh, 17
    mov dl, 13
    call setCursor
    mov si, rule6
    mov bl, 0x0A
    call printStringColor
    
    mov dh, 18
    mov dl, 16
    call setCursor
    mov si, rule7
    mov bl, 0x0C
    call printStringColor
    
    mov dh, 20
    mov dl, 25
    call setCursor
    mov si, startMsg
    mov bl, 0x0A
    call printStringColor
    
    mov dh, 21
    mov dl, 25
    call setCursor
    mov si, exitMsg
    mov bl, 0x0C
    call printStringColor
    
    popa
    ret

; Show game over screen
showGameOver:
    pusha
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x00
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Draw game over box
    mov dh, 7
    mov dl, 15
    call setCursor
    mov ah, 0x09
    mov al, 201
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dh, 7
    mov dl, 16
    call setCursor
    mov ah, 0x09
    mov al, 205
    mov bh, 0
    mov bl, 0x0B
    mov cx, 48
    int 0x10
    
    mov dh, 7
    mov dl, 64
    call setCursor
    mov ah, 0x09
    mov al, 187
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dh, 8
drawGameOverSides:
    cmp dh, 16
    jge drawGameOverBottom
    mov dl, 15
    call setCursor
    mov ah, 0x09
    mov al, 186
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 64
    call setCursor
    int 0x10
    inc dh
    jmp drawGameOverSides

drawGameOverBottom:
    mov dh, 16
    mov dl, 15
    call setCursor
    mov ah, 0x09
    mov al, 200
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    mov dl, 16
    call setCursor
    mov ah, 0x09
    mov al, 205
    mov bh, 0
    mov bl, 0x0B
    mov cx, 48
    int 0x10
    
    mov dl, 64
    call setCursor
    mov ah, 0x09
    mov al, 188
    mov bh, 0
    mov bl, 0x0B
    mov cx, 1
    int 0x10
    
    ; Check win/lose
    cmp word [bricksRemaining], 0
    je printWinMessage
    
    mov dh, 10
    mov dl, 30
    call setCursor
    mov si, gameOverMsg
printGameOverLoop:
    lodsb
    cmp al, 0
    je printFinalScoreLabel
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x4C
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop ax
    jmp printGameOverLoop

printWinMessage:
    mov dh, 10
    mov dl, 32
    call setCursor
    mov si, winMsg
printWinLoop:
    lodsb
    cmp al, 0
    je printFinalScoreLabel
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x4E
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop ax
    jmp printWinLoop

printFinalScoreLabel:
    mov dh, 12
    mov dl, 27
    call setCursor
    mov si, finalScoreMsg
printFinalScoreLoop:
    lodsb
    cmp al, 0
    je printFinalScoreValue
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop ax
    jmp printFinalScoreLoop

printFinalScoreValue:
    mov ax, [score]
    call printNumberWhite
    
    cmp byte [isNewHigh], 1
    jne printPlayAgainMessage
    
    mov dh, 13
    mov dl, 28
    call setCursor
    mov si, newHighMsg
printNewHighLoop:
    lodsb
    cmp al, 0
    je printPlayAgainMessage
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x4A
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop ax
    jmp printNewHighLoop

printPlayAgainMessage:
    mov dh, 14
    mov dl, 19
    call setCursor
    mov si, playAgainMsg
printPlayAgainLoop:
    lodsb
    cmp al, 0
    je gameOverDone
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop ax
    jmp printPlayAgainLoop

gameOverDone:
    popa
    ret

; High score handling
handleHighScoreEnhanced:
    pusha
    mov byte [isNewHigh], 0
    call readHighScore
    cmp ax, 0
    jne compareHighScore
    call createHighScoreFile

compareHighScore:
    mov ax, [score]
    mov bx, [highScoreBuf]
    cmp ax, bx
    jle highScoreDone
    mov [highScoreBuf], ax
    call saveHighScoreWithBackup
    mov byte [isNewHigh], 1

highScoreDone:
    popa
    ret

readHighScore:
    pusha
    lea dx, [highFileName]
    mov al, 0
    mov ah, 0x3D
    int 0x21
    jc readHighScoreFailed
    
    mov bx, ax
    lea dx, [highScoreBuf]
    mov cx, 2
    mov ah, 0x3F
    int 0x21
    jc closeAndFailRead
    
    mov ah, 0x3E
    int 0x21
    popa
    mov ax, 1
    ret

closeAndFailRead:
    mov ah, 0x3E
    int 0x21
readHighScoreFailed:
    mov word [highScoreBuf], 0
    popa
    mov ax, 0
    ret

createHighScoreFile:
    pusha
    lea dx, [highFileName]
    mov cx, 0
    mov ah, 0x3C
    int 0x21
    jc createHighScoreDone
    
    mov bx, ax
    mov word [highScoreBuf], 0
    lea dx, [highScoreBuf]
    mov cx, 2
    mov ah, 0x40
    int 0x21
    
    mov ah, 0x3E
    int 0x21
createHighScoreDone:
    popa
    ret

saveHighScoreWithBackup:
    pusha
    call createBackup
    
    lea dx, [highFileName]
    mov cx, 0
    mov ah, 0x3C
    int 0x21
    jc saveHighScoreFailed
    
    mov bx, ax
    lea dx, [highScoreBuf]
    mov cx, 2
    mov ah, 0x40
    int 0x21
    jc closeAndShowError
    
    mov ah, 0x3E
    int 0x21
    popa
    ret

closeAndShowError:
    mov ah, 0x3E
    int 0x21
saveHighScoreFailed:
    call showSaveError
    popa
    ret

createBackup:
    pusha
    popa
    ret

showSaveError:
    pusha
    mov dh, 24
    mov dl, 25
    call setCursor
    mov si, saveErrorMsg
    mov bl, 0x0C
    call printStringColor
    
    mov cx, 0xFFFF
saveErrorLoop:
    nop
    loop saveErrorLoop
    popa
    ret

; Sound effects
playPaddleSoundEnhanced:
    pusha
    mov word [soundFreq], 1193
    mov word [soundDuration], 2
    call playTone
    
    mov word [soundFreq], 896
    mov word [soundDuration], 1
    call playTone
    popa
    ret

playBounceSoundEnhanced:
    pusha
    mov word [soundFreq], 796
    mov word [soundDuration], 3
    call playTone
    popa
    ret

playBrickSoundEnhanced:
    pusha
    mov word [soundFreq], 1491
    mov word [soundDuration], 2
    call playTone
    
    mov word [soundFreq], 1676
    mov word [soundDuration], 1
    call playTone
    popa
    ret

playLifeLostSoundEnhanced:
    pusha
    mov byte [multiSoundCounter], 5
lifeLostSoundLoop:
    mov ax, 2386
    mov bl, [multiSoundCounter]
    mov bh, 0
    mul bx
    mov [soundFreq], ax
    mov word [soundDuration], 3
    call playTone
    dec byte [multiSoundCounter]
    cmp byte [multiSoundCounter], 0
    jne lifeLostSoundLoop
    popa
    ret

playLevelCompleteSoundEnhanced:
    pusha
    mov byte [multiSoundCounter], 0
levelCompleteSoundLoop:
    cmp byte [multiSoundCounter], 4
    jge levelCompleteSoundDone
    mov al, [multiSoundCounter]
    mov ah, 0
    mov bx, 200
    mul bx
    add ax, 800
    mov [soundFreq], ax
    mov word [soundDuration], 4
    call playTone
    inc byte [multiSoundCounter]
    jmp levelCompleteSoundLoop
levelCompleteSoundDone:
    popa
    ret

playWinSoundEnhanced:
    pusha
    mov byte [multiSoundCounter], 0
winSoundLoop:
    cmp byte [multiSoundCounter], 8
    jge winSoundDone
    mov al, [multiSoundCounter]
    and al, 1
    cmp al, 0
    je winTone1
    mov word [soundFreq], 1047
    jmp playWinTone
winTone1:
    mov word [soundFreq], 784
playWinTone:
    mov word [soundDuration], 6
    call playTone
    inc byte [multiSoundCounter]
    jmp winSoundLoop
winSoundDone:
    popa
    ret

playTone:
    pusha
    mov al, 0xB6
    out 0x43, al
    mov ax, [soundFreq]
    out 0x42, al
    mov al, ah
    out 0x42, al
    
    in al, 0x61
    or al, 0x03
    out 0x61, al
    
    mov cx, [soundDuration]
playToneLoop:
    push cx
    call soundDelay
    pop cx
    loop playToneLoop
    
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    popa
    ret

soundDelay:
    push cx
    mov cx, 0x3FFF
soundDelayLoop:
    nop
    loop soundDelayLoop
    pop cx
    ret

; Utility functions
setCursor:
    pusha
    mov ah, 0x02
    mov bh, 0
    int 0x10
    popa
    ret

printString:
    pusha
printStringLoop:
    lodsb
    cmp al, 0
    je printStringDone
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp printStringLoop
printStringDone:
    popa
    ret

printStringColor:
    pusha
    mov bh, 0
printStringColorLoop:
    lodsb
    cmp al, 0
    je printStringColorDone
    mov ah, 0x09
    mov cx, 1
    int 0x10
    push bx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop bx
    jmp printStringColorLoop
printStringColorDone:
    popa
    ret

printNumber:
    pusha
    mov bx, 10
    mov cx, 0
convertNumber:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convertNumber
printNumberLoop:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    mov bh, 0
    int 0x10
    loop printNumberLoop
    popa
    ret

printNumberWhite:
    pusha
    mov bx, 10
    mov cx, 0
convertNumberWhite:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convertNumberWhite
printNumberWhiteLoop:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    push cx
    mov cx, 1
    int 0x10
    pop cx
    push cx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop cx
    loop printNumberWhiteLoop
    popa
    ret

printNumberYellow:
    pusha
    mov bx, 10
    mov cx, 0
convertNumberYellow:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convertNumberYellow
printNumberYellowLoop:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0E
    push cx
    mov cx, 1
    int 0x10
    pop cx
    push cx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop cx
    loop printNumberYellowLoop
    popa
    ret

printNumberGreen:
    pusha
    mov bx, 10
    mov cx, 0
convertNumberGreen:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convertNumberGreen
printNumberGreenLoop:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0A
    push cx
    mov cx, 1
    int 0x10
    pop cx
    push cx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop cx
    loop printNumberGreenLoop
    popa
    ret

waitForStart:
    mov ah, 0x00
    int 0x16
    ret

; Improved delay system
delay:
    pusha
    movzx ax, byte [gameSpeed]
    mov bx, 0x2FFF      ; Reduced from 0x4FFF for better responsiveness
    mov cx, ax
delayOuterLoop:
    push cx
    mov cx, bx
delayInnerLoop:
    nop
    loop delayInnerLoop
    pop cx
    loop delayOuterLoop
    popa
    ret