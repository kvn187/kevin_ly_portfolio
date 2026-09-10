; ADC Analog Combination Lock
; 2-Channel Version (CH0, CH1)
;
; Features:
;   ADC is checked only when SW9 is raised
;   Each step requires 3 consecutive successful ADC reads
;   If ADC value is outside the valid range, stay in same step
;   User must lower SW9 before next attempt
;
; Steps:
;   Step 0 : Check CH0 three times in range
;   Step 1 : Check CH1 three times in range
;   Success : Unlock

ORG     &H000

; I/O ADDRESS CONSTANTS

ADC_CTRL:           EQU     &HC0        ; Control Register
ADC_STATUS:         EQU     &HC1        ; Status Register
ADC_DATA:           EQU     &HC2        ; Data Register
ADC_CHANNEL:        EQU     &HC3        ; Channel Register

Switches:           EQU     &H000        ; DE10 Switches
LEDs:               EQU     &H001        ; Control LEDs
Timer:              EQU     &H002        ; Timer Peripheral
Hex0:               EQU     &H004        ; 7Seg Hex0
Hex1:               EQU     &H005        ; 7Seg Hex1

; PROGRAM START

Start:                      ; All initialize to 0
        LOAD    Zero        ; AC = 0
        STORE   STATE
        STORE   CUR_CH
        STORE   ADC_VAL
        STORE   COUNT
        STORE   CHECK_OK
        STORE   PASS_COUNT
        OUT     LEDs
        OUT     Hex0
        OUT     Hex1

MainLoop:
        LOAD    STATE
        JZERO   Step0Check

        LOAD    STATE
        SUB     One
        JZERO   Step1Check

        LOAD    STATE
        SUB     Two
        JZERO   Unlocked

        JUMP    MainLoop

; STEP 0 : WAIT FOR SW9, THEN CHECK CH0 3 TIMES

Step0Check:                         ; Level 1
        LOAD    LED_STEP0
        OUT     LEDs
        LOAD    Zero
        OUT     Hex1                ; Display to show Level 1

        CALL    WaitForSW9High      ; Pause until sw9 up

        LOAD    Zero
        STORE   CUR_CH              ; Channel set to 0

        LOAD    Zero
        STORE   CHECK_OK            ; Clear Success Flag

        CALL    CheckStep0_3Times   ; Reads ADC 3 times and varifies if all 3 values in Level 1 PW range

        LOAD    CHECK_OK
        JZERO   Step0Done           ; Redo Level 1 if failed

        ; success -> move to step 1
        LOAD    One
        STORE   STATE
        CALL    ShortDelay

Step0Done:
        CALL    WaitForSW9Low       ; Prevent user to hold sw9 up and retrigger
        JUMP    MainLoop

; STEP 1 : WAIT FOR SW9, THEN CHECK CH1 3 TIMES

Step1Check:
        LOAD    LED_STEP1
        OUT     LEDs
        LOAD    One
        OUT     Hex1

        CALL    WaitForSW9High

        LOAD    One
        STORE   CUR_CH              ; Checking Channel 1

        LOAD    Zero
        STORE   CHECK_OK            ; Success Flag Cleared

        CALL    CheckStep1_3Times   ; Check Channel 1 3 times if all are valid in PW range

        LOAD    CHECK_OK
        JZERO   Step1Done

        ; success -> unlock
        LOAD    Two
        STORE   STATE               ; Set to State 2 = Unlocked
        CALL    ShortDelay

Step1Done:
        CALL    WaitForSW9Low
        JUMP    MainLoop

; UNLOCKED STATE

Unlocked:
        LOAD    LED_UNLOCK
        OUT     LEDs               ; LED unlock pattern displayed
        LOAD    UNLOCK_HEX0
        OUT     Hex0               ; Output unlock value to Hex0
        LOAD    UNLOCK_HEX1
        OUT     Hex1               ; Output unlock value to Hex1

UnlockLoop:
        JUMP    UnlockLoop         ; Unlock forever until reset

; READ ADC SUBROUTINE
; Input : CUR_CH
; Output: ADC_VAL

ReadADC:
        LOAD    CUR_CH             ; Channel Select
        OUT     ADC_CHANNEL

        LOAD    ADC_START          ; ADC_START written to Control Register
        OUT     ADC_CTRL           ; Start Conversion Command sent

WaitReady:
        IN      ADC_STATUS         ; Read ADC Status register
        AND     READY_MASK         ; Mask
        JZERO   WaitReady          ; If Result = 0, ADC not ready

        IN      ADC_DATA
        STORE   ADC_VAL
        RETURN                     ; Latest Conversion Result in ADC_VAL

; CHECK STEP0 THREE TIMES
; Success: CHECK_OK = 1
; Fail   : CHECK_OK remains 0

CheckStep0_3Times:
        LOAD    Zero
        STORE   PASS_COUNT

C0_Loop:
        CALL    ReadADC           ; Reads one ADC sample from current channel

        ; show latest ADC value
        LOAD    ADC_VAL
        OUT     Hex0

        ; ADC_VAL >= LOW0
        LOAD    ADC_VAL
        SUB     LOW0
        JNEG    C0_Fail

        ; ADC_VAL <= HIGH0
        LOAD    HIGH0
        SUB     ADC_VAL
        JNEG    C0_Fail

        ; one success
        LOAD    PASS_COUNT
        ADD     One
        STORE   PASS_COUNT

        ; check if 3 successful reads occur
        LOAD    PASS_COUNT
        SUB     Three
        JZERO   C0_Success

        CALL    TinyDelay
        JUMP    C0_Loop

C0_Fail:
        RETURN

C0_Success:
        LOAD    One
        STORE   CHECK_OK
        RETURN

; CHECK STEP1 THREE TIMES
; Success: CHECK_OK = 1
; Fail   : CHECK_OK remains 0

CheckStep1_3Times:
        LOAD    Zero
        STORE   PASS_COUNT

C1_Loop:
        CALL    ReadADC

        LOAD    ADC_VAL
        OUT     Hex0

        ; ADC_VAL >= LOW1
        LOAD    ADC_VAL
        SUB     LOW1
        JNEG    C1_Fail

        ; ADC_VAL <= HIGH1
        LOAD    HIGH1
        SUB     ADC_VAL
        JNEG    C1_Fail

        ; one success
        LOAD    PASS_COUNT
        ADD     One
        STORE   PASS_COUNT

        ; check if 3 successful reads occur
        LOAD    PASS_COUNT
        SUB     Three
        JZERO   C1_Success

        CALL    TinyDelay
        JUMP    C1_Loop

C1_Fail:
        RETURN

C1_Success:
        LOAD    One
        STORE   CHECK_OK
        RETURN


; WAIT UNTIL SW9 = 1

WaitForSW9High:
WFHighLoop:
        IN      Switches
        AND     SW9_MASK
        JZERO   WFHighLoop        ; if result 0, sw9 low, keep looping
        RETURN

; WAIT UNTIL SW9 = 0

WaitForSW9Low:
WFLowLoop:
        IN      Switches
        AND     SW9_MASK
        JZERO   WFLowDone         ; if result 0, sw9 low, done
        JUMP    WFLowLoop

WFLowDone:
        RETURN

; TINY DELAY
; used between the 3 ADC checks

TinyDelay:
        LOAD    DLY_TINY
        STORE   COUNT

TDLoop:
        LOAD    COUNT
        JZERO   TDDone
        SUB     One
        STORE   COUNT
        JUMP    TDLoop

TDDone:
        RETURN

; SHORT DELAY
; used after successful step transition

ShortDelay:
        LOAD    DLY_SHORT
        STORE   COUNT

SDLoop:
        LOAD    COUNT
        JZERO   SDDone
        SUB     One
        STORE   COUNT
        JUMP    SDLoop

SDDone:
        RETURN

; Variables
STATE:              DW      &H0000
CUR_CH:             DW      &H0000
ADC_VAL:            DW      &H0000
COUNT:              DW      &H0000
CHECK_OK:           DW      &H0000
PASS_COUNT:         DW      &H0000

; Constants
Zero:               DW      &H0000
One:                DW      &H0001
Two:                DW      &H0002
Three:              DW      &H0003

ADC_START:          DW      &H0001
READY_MASK:         DW      &H0001
SW9_MASK:           DW      &H0200      ; bit 9 of Switches

; Thresholds

LOW0:               DW      &H0100
HIGH0:              DW      &H01FF

LOW1:               DW      &H0200
HIGH1:              DW      &H02FF

; LED patterns

LED_STEP0:          DW      &H0001
LED_STEP1:          DW      &H0003
LED_UNLOCK:         DW      &H03FF

; HEX display values

UNLOCK_HEX0:        DW      &H000C
UNLOCK_HEX1:        DW      &H000D

; Delay constants

DLY_TINY:           DW      &H0010
DLY_SHORT:          DW      &H00FF
