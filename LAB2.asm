;******************************************************************************************
;*
;*  Laboratory # 2
;*      
;*   	Program manages the 7-segment display by counting up in 1 second
;*       	intervals on the leftmost display. The count starts at 0 and ends at 9, 
;*  	where it then loops back to 0.
;*
;*  EE3954 Microprocessors and Microcontrollers
;*
;******************************************************************************************

list p=16F87

 __CONFIG 0x3F39     ; Code protect OFF, Debug DISABLED, Flash Write ENABLED
                   	 ; Data EE Protection OFF, Low Voltage Programming DISABLED,
                   	 ; Brown-out detection DISABLED, Power-up Timer ENABLED,
                   	 ; Watchdog Timer DISABLED, XT Oscillator selected

;Initialize special function registers
PORTB	equ	0x06   
TRISB	equ	0x06
PORTD	equ	0x08
TRISD	equ	0x08
PCL	equ	0x02
FSR	equ	0x04
INDF	equ	0x00
STATUS	equ	0x03

W	equ	d'0'		; destination = working register
F	equ	d'1'		; destination = file register
Z	equ	d'2'		; zero bit in STATUS register
RP1 equ	d'6'		; bank select high bit in STATUS register
RP0	equ	d'5'		; bank select low bit in STATUS register
IRP	equ	d'7'		; indirect addressing select bit in STATUS register

GROUP1	udata 0x20		; User general purpose register tags
NUMBER	res 1		; the current count to be displayed	
in_cnt	res 1		; inner delay counter	
mid_cnt	res 1		; middle delay counter
out_cnt	res	1		; outer delay counter
		

	org 0x000
INIT:
	bsf 	STATUS,RP0	;choose bank 1 for memory to set outputs
	clrf	TRISD		;make port D output
	movlw 	b'11100001'   	;make bits 4,3,2,1 in 
	movwf 	TRISB		; PORTB outputs
	bcf 	STATUS,RP0	; choose bank0 in memory
	clrf	NUMBER	; initialize NUMBER to 0
	clrf	PORTD	; initialize all segments off
	clrf	PORTB	; initialize all digits off
	bsf 	PORTB,1	; enable right-most digit

MAIN:				
   	movf    NUMBER,W	; get the next digit to be displayed
   	call    	NUM		; call num to find the code for the next value
    movwf 	PORTD	; display the next value
    call    	DELAY	; call timing loop to delay for one second
    btfss  	PORTB,0x00	; check if RBO is set, if pressed call allon
    call   	allon		; turns on all digits
    incf   	NUMBER,F	; increment NUMBER 
    movlw   d'10'		; Move 10 into working directory to test for overflow
    subwf   NUMBER,W	; subtract 10 from NUMBER
    btfsc   	STATUS,Z	; if zero bit is set, then NUMBER is 10 and
   	clrf    	NUMBER	; NUMBER needs cleared to start back at 0
    nop			; else, no op in order to set breakpoint 
    goto 	MAIN		; repeat main again to display next number

DELAY:
    movlw 	d'167'		; set the outer counter starting value
    movwf 	out_cnt		; to 167

mid_agn:
    movlw	d'176'		; set the middle counter starting value
    movwf	mid_cnt	; to 176

in_agn:
   	movlw 	d'10'		; set the inner counter starting value
   	movwf 	in_cnt		; to 10

in_nxt:
    decfsz 	in_cnt,f		; decrement inner counter
    goto 	in_nxt		; if not zero, decrement again
    decfsz 	mid_cnt,f	; decrement middle counter
    goto 	in_agn		; if not zero, repeat from in_agn
    decfsz 	out_cnt,f	; decrement outer counter
    goto 	mid_agn	; if not zero, repeat from mid_agn
    return

NUM:
    addwf	PCL,F		; jump a number of instructions ahead depending on the 
; current value of the working directory
    retlw	B'00111111'	; return the code for a '0'
    retlw	B'00000110'	; return the code for a '1'
    retlw	B'01011011'	; return the code for a '2'
    retlw	B'01001111'	; return the code for a '3'
    retlw	B'01100110'	; return the code for a '4'
    retlw	B'01101101'	; return the code for a '5'
    retlw	B'01111100'	; return the code for a '6'
    retlw	B'00000111'	; return the code for a '7'
    retlw	B'01111111'	; return the code for a '8'
    retlw	B'01100111'	; return the code for a '9'

allon:
   	movlw 	B'00011110'	; enable all digits
    movwf 	PORTB	;
    return

end
 
    
