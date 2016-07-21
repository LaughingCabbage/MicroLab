;The following is existing code from the powerpoint slides. NEEDS DEBUGGING :(
    
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;FORCED CONFIGURATION ADJUSTMENTS FOR NEWER COMPILER + MPLAB
;MAY NEED TO ADJUST IN LAB
    
#include "p16F87.inc"

; CONFIG1
; __config 0xFFFF
 __CONFIG _CONFIG1, _FOSC_EXTRCCLK & _WDTE_ON & _PWRTE_OFF & _MCLRE_ON & _BOREN_ON & _LVP_ON & _CPD_OFF & _WRT_OFF & _CCPMX_RB0 & _CP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _FCMEN_ON & _IESO_ON
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

;!!!!!!!!!!!!!!!!!!!!!
;trouble with tags in newer IDE
;
 
PORTB	equ 0x06    ;tags
;TRISB	equ 0x06
PORTD	equ 0x08
TRISD	equ 0x08
PLC equ	0x02
FSR equ	0x04
INDF	equ 0x00
STATUS	equ 0x03
W  equ	d'0'
F  equ	d'1'
Z  equ	d'2'
RP1 equ d'6'
RP0 equ d'5'
IRP equ d'7'

 ;General Purpouse Register tags
GROUP1	udata 0x20
NUMBER	res 1
in_cnt	res 1
mid_cnt	res 1
out_cnt	res 1
	
	
	org 0x000
	
	bsf STATUS,RP0	;choose bank 1
	clrf	TRISD	;make port D output
	movlw b'11100001'   ;make 4,3,2,1 outputs
	movwf TRISB
	bcf STATUS,RP0
	clrf	NUMBER
	clrf	PORTD
	clrf	PORTB
	bsf PORTB,1
	
MAIN:	nop
    movf    NUMBER,W
    call    NUM
    movwf   PORTD
    call    DELAY
    btfss   PORTB,0x00
    call    allon
    
    incf    NUMBER,F
    movlw   d'10'
    subwf   NUMBER,W
    btfsc   STATUS,Z
    clrf    NUMBER
    goto MAIN
    
DELAY:	
    movlw d'167'
    movwf out_cnt
mid_agn:
    movlw	d'176'
    movwf mid_cnt
in_agn:
    movlw d'10'
    movwf   in_cnt
in_nxt:
    decfsz in_cnt,f
    goto in_nxt
    decfz mid_cnt,f
    goto in_agn
    decfsz  out_cnt,f
    goto mid_agn
    return
    
NUM:
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

allon:
    movlw   B'00011110'
    movwf   PORTB
    return
    	
end
 
    
