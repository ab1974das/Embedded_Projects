.INCLUDE "M32DEF.INC"
.ORG 0x0000
    RJMP RESET

RESET:
    ; Stack initialization
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16

    ; PORTC output for bit-count LEDs
    LDI R16, 0xFF
    OUT DDRC, R16
    CLR R16
    OUT PORTC, R16

    ; UART initialization: RX + TX enabled
    LDI R16, 0x18
    OUT UCSRB, R16

    ; Asynchronous USART, 8 data bits, 1 stop bit, no parity.
    ; URSEL must be set on ATmega32 when writing UCSRC.
    LDI R16, 0x86
    OUT UCSRC, R16

    ; UBRR = 51 for 9600 baud at 8 MHz, normal speed.
    LDI R16, 51
    OUT UBRRL, R16
    CLR R16
    OUT UBRRH, R16

MAIN_LOOP:
    ; Wait for received byte
    SBIS UCSRA, RXC
    RJMP MAIN_LOOP
    IN R17, UDR

    ; Count set bits in received byte
    CLR R18              ; count = 0
    LDI R19, 8            ; eight bits
COUNT_ONES:
    LSR R17               ; original bit 0 moves to Carry
    BRCC SKIP_COUNT
    INC R18
SKIP_COUNT:
    DEC R19
    BRNE COUNT_ONES

    ; Display numerical count on PORTC LEDs
    OUT PORTC, R18

    ; Convert count 0..8 to ASCII character '0'..'8'
    MOV R20, R18
    SUBI R20, -'0'

TX_WAIT:
    SBIS UCSRA, UDRE
    RJMP TX_WAIT
    OUT UDR, R20

    RJMP MAIN_LOOP
