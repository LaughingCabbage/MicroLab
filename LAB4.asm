    list p=16f877

#include P16F877.INC

    _CONFIG	0x3F39

; Define some 8-bit file register labels
; 
PCL	equ	0x02	; in ALL BANKS - used for computed goto
PORTB	equ	0x06	; in BANK 0 digit enables and RB0
TRISB	equ	0x06	; in BANK 0 data direction for digits and RB0
TRISA	equ	0x05	; in BANK 1 data direction for A/D and KeyPad
PORTD	equ	0x08	; in BANK 0 segment data port
TRISD	equ	0x08	; in BANK 1 data direction-segments
D1	equ	0x71	; in ALL BANKS - for leftmost digit (1's volt)
D2	equ	0x72	; in ALL BANKS - for next leftmost digit (0.1's volt)
ADRES	equ	0x78	; in ALL BANKS - for rotating A/D result
CNT1	equ	0x21	; in BANK 0 for 4 ms delay routine outer
CNT2	equ	0x22	; in BANK 0 for 4 ms delay routine inner
DIGIT	equ	0x24	; in BANK 0 for digit counter routine
STATUS	equ	0x03	; in ALL BANKS - status register
ADCON0	equ	0x1f	; in BANK0 - A/D converter control reg0.
ADCON1	equ	0x1f	; in BANK1 - A/D converter control reg1.
ADRESH	equ	0x1e	; in BANK0 - A/D converter result high byte
PIR1	equ	0x0c	; in BANK0 - A/D converter Flag in bit6
W	equ	d'0'	; destination=W  ('working' register)
F	equ	d'1'	; destination=f
C	equ	d'0'	; "carry" flag bit in status reg.
Z	equ	d'2'	; "zero"flag bit in status reg.
RP1	equ	d'6'	; bank select high bit in status reg.
RP0	equ	d'5'	; bank select low bit in status reg.
ADIF	equ	d'6'	; A/D converter done flag bit in PIR1
ADGO	equ	d'2'	; A/D converter start, in ADCON0

	org	0x0000
	nop
	
INIT:	
	clrf 	STATUS		;         select BANK 0
	clrf	PORTD		; initially set all segments off
	clrf	PORTB		; initially set all digits off
	clrf	D1		;  --------
	clrf	D2		; CLEAR all DIGIT registers
	bsf	STATUS,RP0		;         select BANK 1
	clrf	TRISD		; set PORTD segment driver bits as outputs
	movlw	B'11100001'		; Port B bits 4,3,2,1 Digit driver bits, RB0=pushbutton input
	movwf	TRISB		; set port B bits 7,6,5 inputs, 4,3,2,1 outputs, RB0 to input
	movlw	B'11111111'		; data for setting A/D and Keypad for inputs.
	movwf	TRISA		; set all A/D and Keypad (a1,a2,a3,a4) to inputs.
	movlw	B'00001110'		; make A/D AN0 = analog, all others digital,
	movwf	ADCON1		;  - left justified result & Vref = Vdd,Vss
	bcf	STATUS,RP0		;         select BANK 0
	movlw	B'01000001'		; select 1:8 Conversion clock(2us),Vin-AN0,
	movwf	ADCON0		;  - GO/DOne = no go, ADON = ON (sample/hold starts)
	bcf	PIR1,ADIF		; make sure A/D converter flag bit = 0
	
; Main program just keeps displaying D1,D2 on 7-segment displays
;   takes a little over 8 ms since delay called 2 times
;	A/D converter has Tacq = 20 us, so 8ms wait before A/D GO:
;
MAIN:	
	movf	D2,W		; get tenths digit display code
	movwf	PORTD		; send display code to port
	bsf	PORTB,2		; turn on  tenths digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTB,2		; turn off tenths digit

	movf	D1,W		; get 1's digit display code
	movwf	PORTD		; send display code to port
	bsf	PORTB,1		; turn on  1's digit
	call	DELAY4		; call 4 ms delay
	bcf	PORTB,1		; turn off 1's digit
; Now Go Convert the potentiometer's voltage:
	bsf	ADCON0,ADGO	; start conversion - SET "GO"
ADONE:	
	btfsc	ADCON0,ADGO	; test to see if conversion is complete
	goto	ADONE		; if not done with conversion, go back and test again
	call	GETAD		; if it is done, get its value and update digits
	goto	MAIN		; after reading a/d converter go display digits.
;	GETAD Subroutine, Reads ADRESH, shifts it right 5 times to get 3 MSBits
;	   gets display codes and stores them in D1,D2. Clears ADIF
;
GETAD:	
	movf	ADRESH,W	;get A/D converter result high byte
	movwf	ADRES		; put result in temp register
	rrf	ADRES,F		; Rotate it once
	rrf	ADRES,F		; Rotate it second time
	rrf	ADRES,F		; Rotate it third time
	rrf	ADRES,F		; Rotate it fourth time
	rrf	ADRES,F		; Rotate it fifth time
	movlw	B'00000111'	; Mask data for lower 3 bits
	andwf	ADRES,F		; AND result - put it in ADRES
	movf	ADRES,W		; put it in W for computed goto
	call	TENTHS		; go get display code for tenths of volt
	movwf	D2		;  put code in display register (tenths)
	movf	ADRES,W		; get A/D result into W for computed goto
	call	ONES		; go get display code for ones of volt
	movwf	D1		;  put code in display register (ones)
	return			; done with A/D conversion and display update
;
;	Subroutine: TENTHS 
;	Input: 	W - A/D Converter result ( decimal 0 to 8 )
;	Output:	W - the display code for tenths of volts
;	This subroutine takes 3 instructions cycles by itself (5 including the call)
;
TENTHS:	
	addwf	PCL,F		; 1
	retlw	B'01001111'	; 2 - if A/D = 000, return a '3'
	retlw	B'01100111'	; 2 - if A/D = 001, return a '9'
	retlw	B'01111100'	; 2 - if A/D = 010, return a '6'
	retlw	B'00000110'	; 2 - if A/D = 011, return a '1'
	retlw	B'01111111'	; 2 - if A/D = 100, return a '8'
	retlw	B'01100110'	; 2 - if A/D = 101, return a '4'
	retlw	B'00000110'	; 2 - if A/D = 110, return a '1'
	retlw	B'00000111'	; 2 - if A/D = 111, return a '7'

;
;	Subroutine: ONES 
;	Input: 	W - A/D Converter result ( decimal 0 to 8 )
;	Output:	W - the display code for Integer - ones of volts
;	  Display code includes Decimal Point on.
;	This subroutine takes 3 instructions cycles by itself (5 including the call)
;
ONES:	
	addwf	PCL,F		; 1
	retlw	B'10111111'	; 2 - if A/D = 000, return a '0'
	retlw	B'10111111'	; 2 - if A/D = 001, return a '0'
	retlw	B'10000110'	; 2 - if A/D = 010, return a '1'
	retlw	B'11011011'	; 2 - if A/D = 011, return a '2'
	retlw	B'11011011'	; 2 - if A/D = 100, return a '2'
	retlw	B'11001111'	; 2 - if A/D = 101, return a '3'
	retlw	B'11100110'	; 2 - if A/D = 110, return a '4'
	retlw	B'11100110'	; 2 - if A/D = 111, return a '4'

; Subroutine: DELAY4 = 4 millisecond delay
; delay = 1+(3 * (1+3*cnt2)*cnt1
; equation does not include  2 + 2 for call and return
; simulator stopwatch shows 3.981 ms
;
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

	end			;Compiler directive to quit compiling
