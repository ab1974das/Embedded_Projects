; ============================================================
; 10th-order (11-tap) fixed-point FIR LOW-PASS filter - ATmega32
; Passes 1 Hz sine, attenuates 30 Hz sine

.INCLUDE "M32DEF.INC"
.ORG 0x0000

; ---- Stack pointer ----
    LDI  R16, HIGH(RAMEND)
    OUT  SPH, R16
    LDI  R16, LOW(RAMEND)
    OUT  SPL, R16

; ---- I/O ----
    LDI  R16, 0xFF
    OUT  DDRB, R16              ; PORTB -> DAC0808
    OUT  DDRD, R16

; ---- ADC: AVcc ref, left adjust, ADC0, enabled, clk/128 ----
    LDI  R16, (1<<REFS0)|(1<<ADLAR)
    OUT  ADMUX, R16
    LDI  R16, 0x87
    OUT  ADCSRA, R16

; ---- Timer1: CTC, clk/64, 100 Hz tick ----
; OCR1A = F_CPU/(64*100) - 1 = 1249 for 8 MHz
; (for 1 MHz use clk/8: TCCR1B = 0x0A, OCR1A stays 1249)
    CLR  R16
    OUT  TCCR1A, R16
    LDI  R16, HIGH(1249)
    OUT  OCR1AH, R16
    LDI  R16, LOW(1249)
    OUT  OCR1AL, R16
    LDI  R16, (1<<WGM12)|(1<<CS11)|(1<<CS10)
    OUT  TCCR1B, R16

; ---- Zero register and delay line preload (mid-scale = 128) ----
    CLR  R22
    LDI  R16, 128
    MOV  R2,  R16
    MOV  R3,  R16
    MOV  R4,  R16
    MOV  R5,  R16
    MOV  R6,  R16
    MOV  R7,  R16
    MOV  R8,  R16
    MOV  R9,  R16
    MOV  R10, R16
    MOV  R11, R16
    MOV  R12, R16

MAIN:
    ; ---- Wait for 100 Hz sample tick ----
    SBIS TIFR, OCF1A
    RJMP MAIN
    LDI  R16, (1<<OCF1A)
    OUT  TIFR, R16              ; clear flag by writing 1

    ; ---- Start ADC conversion and wait ----
    SBI  ADCSRA, ADSC
CONV:
    SBIC ADCSRA, ADSC
    RJMP CONV
    IN   R16, ADCH              ; 8-bit sample

    ; ---- Shift delay line, insert new sample ----
    MOV  R12, R11
    MOV  R11, R10
    MOV  R10, R9
    MOV  R9,  R8
    MOV  R8,  R7
    MOV  R7,  R6
    MOV  R6,  R5
    MOV  R5,  R4
    MOV  R4,  R3
    MOV  R3,  R2
    MOV  R2,  R16

    ; ---- Accumulator = 128 (rounding for >>8) ----
    LDI  R20, 128
    CLR  R21

    ; ---- y = sum( c[k] * x[k] ) ----
    LDI  R16, 1                 ; c0 = 1
    MUL  R2, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 4                 ; c1 = 4
    MUL  R3, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 15                ; c2 = 15
    MUL  R4, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 32                ; c3 = 32
    MUL  R5, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 49                ; c4 = 49
    MUL  R6, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 54                ; c5 = 54 (center tap)
    MUL  R7, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 49                ; c6 = 49
    MUL  R8, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 32                ; c7 = 32
    MUL  R9, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 15                ; c8 = 15
    MUL  R10, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 4                 ; c9 = 4
    MUL  R11, R16
    ADD  R20, R0
    ADC  R21, R1

    LDI  R16, 1                 ; c10 = 1
    MUL  R12, R16
    ADD  R20, R0
    ADC  R21, R1


    OUT  PORTB, R21

    RJMP MAIN
