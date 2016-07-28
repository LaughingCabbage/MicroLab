
PCL	equ	0x02	; in ALL BANKS - used for computed goto
PORTB	equ	0x06	; in BANK 0 digit enables and RB0
TRISB	equ	0x06	; in BANK 0 data direction for digits and RB0
PORTD	equ	0x08	; in BANK 0 segment data port
TRISD	equ	0x08	; in BANK 1 data direction-segments
INTCON	equ	0x0B	; in ALL BANKS contains GIE,T0IE,T0IF
OPTREG	equ	0x01	; in BANK 1 option register - timero setup
TMR0	equ	0x01	; in BANK 0 timer0 start count value
D1	equ	0x71	; in ALL BANKS - for 1000's digit
D2	equ	0x72	; in ALL BANKS - for 100's digit
D3	equ	0x73	; in ALL BANKS - for 10's digit
D4	equ	0x74	; in ALL BANKS - for 1's digit
TEMPW	equ	0x78	; in ALL BANKS - for context saving W in ISR
TEMPS	equ	0x79	; in ALL BANKS - for context saving STATUS in ISR
C1TMP	equ	0x7A	; in ALL BANKS - for context saving CNT1
C2TMP	equ	0x7B	; in ALL BANKS - for context saving CNT2
CNT1	equ	0x21	; in BANK 0 for 4 ms delay routine outer
CNT2	equ	0x22	; in BANK 0 for 4 ms delay routine inner
DIGIT	equ	0x24	; in BANK 0 for digit counter routine
STATUS	equ	0x03	; in ALL BANKS - status register

;  Now define some BIT labels...
;
W	equ	d'0'	; destination=W  ('working' register)
F	equ	d'1'	; destination=f
C	equ	d'0'	; "carry" flag bit in status reg.
Z	equ	d'2'	; "zero"flag bit in status reg.
RP1	equ	d'6'	; bank select high bit in status reg.
RP0	equ	d'5'	; bank select low bit in status reg.
INTEDG	equ	d'6'	; RB0 edge, 1=rising,0=falling, in OPTION_REG
GIE	equ	d'7'	; global interrupt enable in INTCON
T0IE	equ	d'5'	; timer 0 interrupt enable in INTCON
T0IF	equ	d'2'	; timer 0 interrupt flag in INTCON

;  Executable part of program starts here...  
;  Start at the reset vector
;
	org	0x0000	; program starts at Program Memory location 0x0000
	nop		; put here so we can breakpoint at 0x0000
	goto	INIT	; go set up registers
	org	0x0004	; interrupt vector location
	goto	ISR	; goto Interrupt Service Routine on Timer0 Interrupt
;  First allow program to initialize registers
;
INIT:	
	clrf 	STATUS		;         select BANK 0
	clrf	PORTD		; initially set all segments off
	clrf	PORTB		; initially set all digits off
	clrf	D1		;  --------
	clrf	D2		; CLEAR all DIGIT registers
	clrf	D3		;  for counter
	clrf	D4		;  --------
	bsf	STATUS,RP0	;         select BANK 1
	clrf	TRISD		; set PORTD segment driver bits as outputs
	movlw	B'11100001'	; Port B bits 4,3,2,1 Digit driver bits, RB0=pushbutton input
	movwf	TRISB		; set port B bits 7,6,5 inputs, 4,3,2,1 outputs, RB0 to input
	movlw	b'11010101'	; data for timer0 control: INST CLK,PRESCALER=TMR0 & 1:64
	movwf	OPTREG		; write data to OPTION_REG, start timer0 
	bcf	STATUS,RP0	;         select BANK 0
	movlw	0x64		; starting value for timer0 (156 counts of 64us)
	movwf	TMR0		; writing to TMR0 resets prescaler, starts counter
	bsf	INTCON,T0IE	; enable timer0 to allow interrupts
	bsf	INTCON,GIE	; enable all interrupts (timer0 only one enabled)

; Main program just keeps displaying D1,D2,D3,D4 on 7-segment displays
;   takes a little over 16 ms since delay called 4 times
;
MAIN:	
	movf	D4,W		; get 1's digit count value
	call	TABLE		; go get display code 
	movwf	PORTD		; send display code to port
	bsf	PORTB,4		; turn on  1's digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTB,4		; turn off 1's digit

	movf	D3,W		; get 10's digit count value
	call	TABLE		; go get display code 
	movwf	PORTD		; send display code to port
	bsf	PORTB,3		; turn on  10's digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTB,3		; turn off 10's digit
	movf	D2,W		; get 100's digit count value
	call	TABLE		; go get display code 
	movwf	PORTD		; send display code to port
	bsf	PORTD,7		; turn on decimal point
	bsf	PORTB,2		; turn on  100's digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTD,7		; turn off decimal point
	bcf	PORTB,2		; turn off 100's digit

	movf	D1,W		; get 1000's digit count value
	call	TABLE		; go get display code 
	movwf	PORTD		; send display code to port
	bsf	PORTB,1		; turn on  1000's digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTB,1		; turn off 1000's digit
	goto	MAIN		; go back and do it all again

; Subroutine to increment ( D1 D2 D3 D4 ) digits
INC_DIG:
	incf	D4,W		; increment 1's digit, result in W
	sublw	d'10'		; test to see if it is 10 yet
	btfss	STATUS,Z	; skip next if it is 10
	goto	DONE4		; it is not ten - go store it and return
	clrf	D4		; it is ten - so clear digit and inc 10's

	incf	D3,W		; increment 10's digit, result in W
	sublw	d'10'		; test to see if it is 10 yet
	btfss	STATUS,Z	; skip next if it is 10
	goto	DONE3		; it is not ten - go store it and return
	clrf	D3		; it is ten - so clear digit and inc 100's

	incf	D2,W		; increment 100's digit, result in W
	sublw	d'10'		; test to see if it is 10 yet
	btfss	STATUS,Z	; skip next if it is 10
	goto	DONE2		; it is not 10 - go store it and return
	clrf	D2		; it is ten - so clear digit and inc 1000's

	incf	D1,W		; increment 1000's digit, result in W
	sublw	d'10'		; test to see if it is 10 yet
	btfss	STATUS,Z	; skip next if it is 10
	goto	DONE1		; it is not 10 - go store it and return
	clrf	D1		; it is ten - so clear digit 
	return			; they should all be zero now

DONE1:	
	incf	D1,F		;   store incrementd value 1000's
	return			;   and return
DONE2:	
	incf	D2,F		;   store incremented value 100's
	return			;   and return	
DONE3:	
	incf	D3,F		;   store incremented value 10's 
	return			;   and return
DONE4:	
	incf	D4,F		;   store incremented value 1's
	return			;   and return
	
;	Subroutine: TABLE 
;	Input: 	W - the numeral you want to display
;	Output:	W - the code for the numeral
;	This subroutine takes 3 instructions cycles by itself (5 including the call)
;
TABLE:	
	addwf	PCL,F		; 1
	retlw	B'00111111'	; 2 - return the code for a '0'
	retlw	B'00000110'	; 2 - return the code for a '1'
	retlw	B'01011011'	; 2 - return the code for a '2'
	retlw	B'01001111'	; 2 - return the code for a '3'
	retlw	B'01100110'	; 2 - return the code for a '4'
	retlw	B'01101101'	; 2 - return the code for a '5'
	retlw	B'01111100'	; 2 - return the code for a '6'
	retlw	B'00000111'	; 2 - return the code for a '7'
	retlw	B'01111111'	; 2 - return the code for a '8'
	retlw	B'01100111'	; 2 - return the code for a '9'
	
DELAY4:
	movlw	d'159'		; load outer counter value
	movwf	CNT1		; store it in temp register
	
INN4:	
	movlw	d'7'		; load inner counter value
	movwf	CNT2		; store it in temp register
	
NXT4:	
	decfsz	CNT2,F		; decrement inner counter until zero
	goto	NXT4		; if inner not zero, keep decrementing inner
	decfsz	CNT1		; if inner is zero, then decrement outer
	goto	INN4		; if outer not zero, do inner again
	return			; if outer is zero, return from subroutine
	
ISR:	
	nop			; just so I can breakpoint here
;context saving occurs here:
	movwf	TEMPW		; store contents of W 
	swapf	STATUS,W	; swap status register, put in W
	movwf	TEMPS		; store old status (swapped)
;  now reset timer 0 counter values
	movlw	0x64		; starting value for timer0 
	movwf	TMR0		; load timer0, resets prescaler also
	call	INC_DIG		; call to increment digits value
	bcf	INTCON,T0IF	; clear the timer0 interrupt flag
;context restoring occurs here:
	swapf	TEMPS,W		; get old status reg into W
	movwf	STATUS		; restore STATUS register
	swapf	TEMPW,F		; swap nibbles- don't affect status bits
	swapf	TEMPW,W		; swap again - don't afffect status, W restored
	retfie			; return from interrupt

end
