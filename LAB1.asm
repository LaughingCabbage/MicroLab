
#include "p16F87.inc"

; CONFIG1
; __config 0xFFFF
 __CONFIG _CONFIG1, _FOSC_EXTRCCLK & _WDTE_ON & _PWRTE_OFF & _MCLRE_ON & _BOREN_ON & _LVP_ON & _CPD_OFF & _WRT_OFF & _CCPMX_RB0 & _CP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _FCMEN_ON & _IESO_ON

FSR	equ 0x04
INDF	equ 0x00
STATUS	equ 0x03
ENDADR	equ 0x73
W   equ d'0'
F   equ d'1'
IRP equ	d'7'
Z   equ	d'2'

    org 0x000
MAIN: 
    nop
    
    bcf	STATUS,IRP
    movlw 0x20
    movwf FSR
    movlw 0x70
    movwf ENDADR
    call FLNXT
    
    movlw 0xA0
    movwf FSR
    movlw 0xF0
    movwf ENDADR
    call FLNXT
    
    bsf STATUS,IRP
    movlw 0x10
    movwf FSR
    movlw 0x70
    movwf ENDADR
    call FLNXT
    
    movlw 0x90
    movwf FSR
    movlw 0xE5
    movwf ENDADR
    call FLNXT
STAYHR:	goto STAYHR
    
FLNXT: movlw 0x44
    movwf INDF
    incf FSR,F
    movf ENDADR,W
    subwf FSR,W
    btfss STATUS,Z
    goto FLNXT
    nop
    return
 
 end