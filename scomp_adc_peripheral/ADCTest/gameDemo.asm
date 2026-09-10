ORG 0

; ADC Target Game
; Hex Definition:
;     HEX3 HEX2 = Target
;     HEX1 HEX0 = Current ADC/player value
; LED Definition:
;     LED0 = too low
;     LED1 = too high
;     All LEDs on = within target range / win
; Game flow:
; 1. Initialize variables
; 2. Wait until all switches are down
; 3. Generate a random 8-bit target when sw9 up
; 4. Display the target
; 5. Read ADC input through the peripheral
; 6. Scale ADC value from 12 bits to 8 bits
; 7. Display current ADC value
; 8. Compare ADC value to target
; 9. Show feedback on LEDs
; 10. If player wins, pause, increment score, and start next round

Start:
    CALL Init               ; initalize game

MainLoop:
    CALL WaitAllDown        ; wait until all switches are off
    CALL GenerateTarget     ; generates a random target
    CALL DisplayTarget      ; show the target on HEX3 HEX2

    LOAD ZeroVal            ; AC = 0
    OUT LEDs                ; clear LEDs at the start of a new round

GameLoop:
    CALL ReadADC            ; reads analog input through ADC peripheral
    CALL DisplayCurrentValue ; show current ADC value on HEX1 HEX0
    CALL CompareToTarget    ; check if ADC value is within range
    CALL DisplayFeedback    ; shows: too low / too high / win on LEDs

    LOAD WinFlag            ; AC = WinFlag
    JZERO GameLoop          ; keep playing until player wins / WinFlag = 0

    CALL WinPause           ; hold win display / LEDs briefly
    CALL IncrementScore     ; increase player's score
    JUMP MainLoop           ; start next round


Init:                       ; all variables set to 0
    LOAD ZeroVal
    STORE Counter
    STORE Target
    STORE ADCValue
    STORE WinFlag
    STORE Score
    STORE Diff
    STORE DelayCount
    RETURN



WaitAllDown:               ; waits until all switches are down
    IN Switches            ; AC = switches
    OUT LEDs               ; LEDs display switch value
    JNZ WaitAllDown        ; if AC isn't zero loop again
    RETURN



GenerateTarget:           ; counts up like Lab8 until sw9 is raised
GenLoop:
    LOAD Counter          ; AC = counter
    ADDI 1                ; AC = AC + 1
    STORE Counter         ; Counter = AC, counter increasing

    IN Switches           ; read switch states
    OUT LEDs              ; switches shown on LEDs
    AND SW9Mask           ; bit mask to just sw9
    JZERO GenLoop         ; if sw9 not on loop back

    LOAD Counter          ; final counter value
    AND Mask8Bit          ; keep lower 8 bits, value = 0 - 255
    STORE Target          ; save as current round target
    RETURN



DisplayTarget:
    LOAD Target           ; loads the 8bit target
    AND LowNibbleMask     ; keep only the bottom 4 bits
    OUT Hex2              ; low nibble / 4bits of target to Hex2

    LOAD Target           ; loads the 8bit target
    SHIFT -4              ; high nibble now in lower 4 bits
    AND LowNibbleMask     ; keep only the bottom 4 bits
    OUT Hex3              ; high nibble / 4bits of target to Hex3
    RETURN



DisplayCurrentValue:
    LOAD ADCValue         ; loads the ADC value
    AND LowNibbleMask     ; keep only the bottom 4 bits
    OUT Hex0              ; low nibble of ADC value

    LOAD ADCValue         ; loads the ADC value
    SHIFT -4              ; high nibble now in lower 4 bits
    AND LowNibbleMask     ; keep only the bottom 4 bits
    OUT Hex1              ; high nibble of ADC value
    RETURN



ReadADC:                    ; select ADC channel, clear ready, convert, poll, read
    LOADI 0                 ; AC = 0
    OUT ADC_CHAN            ; select ADC channel 0

    LOADI 2                 ; AC = 2
    OUT ADC_CTRL            ; CLEAR_READY

    LOADI 1                 ; AC = 1
    OUT ADC_CTRL            ; START conversion

PollADC:
    IN ADC_STAT             ; read ADC status
    AND OneVal              ; check READY at bit 0
    JZERO PollADC           ; wait until ready = 1

    IN ADC_DATA             ; read ADC result
    STORE ADCValue          ; store ADC result

    LOAD ADCValue           ; read ADC result again
    SHIFT -4                ; scale 12bit ADC to 8bit
    AND Mask8Bit            ; lower 8bit remains
    STORE ADCValue          ; store the lower 8bit result
    RETURN



CompareToTarget:            ; win conditions
    LOAD ZeroVal            ; AC = 0
    STORE WinFlag           ; WinFlag = 0
    
    LOAD ADCValue           ; load player value
    SUB Target              ; AC = ADCValue - Target
    STORE Diff              ; store the diff

    ; absValue
    JPOS DiffPositive
    LOAD ZeroVal
    SUB Diff                ; if Diff was negative now it's pos
    STORE Diff

DiffPositive:
    LOAD Diff
    SUB Tolerance
    JPOS NotWin             ; if AC > 0 player hasn't won yet

    LOAD OneVal             ; AC = 1, diff within tolerance (4)
    STORE WinFlag           ; WinFlag = 1
    RETURN

NotWin:
    RETURN



DisplayFeedback:            ; ADCValue < Target = LED0 on, else LED1 on
    LOAD WinFlag
    JZERO CheckHighLow      ; if 0, check if player value too high or low

    LOAD AllOn              ; LEDs all on to show win
    OUT LEDs                ; LEDs display win
    RETURN

CheckHighLow:
    LOAD ADCValue           ; load player value
    SUB Target              ; AC = ADCValue - Target
    JPOS TooHigh            ; if positive player is too high

TooLow:
    LOAD LED0On             ; LED0 on since player too low
    OUT LEDs
    RETURN

TooHigh:
    LOAD LED1On             ; LED1 on since player too high
    OUT LEDs
    RETURN



WinPause:
    LOAD DelayCountInit     ; delay for win display
    STORE DelayCount

WinPauseLoop:
    LOAD DelayCount
    ADDI -1
    STORE DelayCount
    JZERO WinPauseDone
    JUMP WinPauseLoop

WinPauseDone:
    RETURN



IncrementScore:            ; internal score increment after winning round
    LOAD Score             ; load current score
    ADDI 1                 ; score increment
    AND Mask8Bit           ; wrap score around 255
    STORE Score            ; store score
    RETURN


; I/O Addresses
Switches    EQU 000
LEDs        EQU 001
Hex0        EQU 004
Hex1        EQU 005
Hex2        EQU 006
Hex3        EQU 007

; ADC peripheral register addresses
ADC_CTRL    EQU &HC0
ADC_STAT    EQU &HC1
ADC_DATA    EQU &HC2
ADC_CHAN    EQU &HC3


; Constants
ZeroVal:        DW 0
OneVal:         DW 1
Tolerance:      DW 4
Mask8Bit:       DW &H00FF
LowNibbleMask:  DW &H000F
SW9Mask:        DW &H0200
LED0On:         DW &H0001
LED1On:         DW &H0002
AllOn:          DW &H03FF
DelayCountInit: DW 5000


; Variables
Counter:        DW 0
Target:         DW 0
ADCValue:       DW 0
WinFlag:        DW 0
Score:          DW 0
Diff:           DW 0
DelayCount:     DW 0
