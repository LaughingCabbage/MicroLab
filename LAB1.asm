;******************************************************************************************
;*
;*  Laboratory # 1
;*      
;*          Program writes the 0x44 to all general purpose registers (excluding
;*          locations 0x70 - 0x7F and 0x1E5 - 0X1EF) using indirect addressing
;*          The program is based heavily on code from the powerpoint slides.
;*  
;*  EE3954 Microprocessors and Microcontrollers
;*
;******************************************************************************************

list p=16F87

 __CONFIG 0x3F39     ; Code protect OFF, Debug DISABLED, Flash Write ENABLED
                   	 ; Data EE Protection OFF, Low Voltage Programming DISABLED,
                   	 ; Brown-out detection DISABLED, Power-up Timer ENABLED,
                   	 ; Watchdog Timer DISABLED, XT Oscillator selected


FSR		equ 0x04		; holds address for indirect addressing
INDF		equ 0x00		; INDF register required for indirect addressing
STATUS	equ 0x03		; STATUES register for accessing IRP and Z bits
ENDADR	equ 0x73		; holds the current ending address

W  	 	equ d'0' 		; sets the destination as the working register
F   	equ d'1'		; sets the destination as the current register
IRP equ	d'7'            		; Bank select bit in STATUS register
Z   equ	d'2'            		; Zero bit in STATUS register

   	org 0x000 	        	; program starting location at 0x0000
MAIN: 
    nop			; nop required by older MPLAB ICD systems	
   	bcf STATUS,IRP     ; choose bank 0/1 for indirect address
    movlw 0x20       	; load bank 0 start address
    movwf FSR        	; store start address in FSR
    movlw 0x70          	; load bank 0 end address
    movwf ENDADR      ; store end address
    call FLNXT          	; fill bnak 0

	movlw 0xA0          	; load bank 1 start address
    movwf FSR           	; store start address in FSR
    movlw 0xF0          	; load bank 1 end address
    movwf ENDADR     	; store end address
    call FLNXT          	; fill bank 1

    bsf STATUS,IRP     	; switch to bank 2/3 for indirect addresses
    movlw 0x10          	; load bank 2 start address
    movwf FSR           	; store start address in FSR
    movlw 0x70          	; load bank 2 end address
    movwf ENDADR      ; store end address
    call FLNXT          	; fill bank 2

    movlw 0x90          	; load bank 3 start address
   	movwf FSR           	; store start address in FSR
   	movlw 0xE5          	; load bank 3 end address
    movwf ENDADR     	; store end address
	call FLNXT          	; fill bank 3

STAYHR:
	goto STAYHR     	; program is finished, loop to idle
    
FLNXT: 	
	movlw 0x44       	; load the required data to working register
    movwf INDF          	; store data using indirect addressing
    incf FSR,F          	; increment the address in FSR
    movf ENDADR,W   	; load end address into working register
    subwf FSR,W        	; check if FSR is at end address
    btfss STATUS,Z      ; if FSR = end bank, then don't loop
    goto FLNXT          	; else, write data into the next memory bank
    nop                 	; nop, for setting a breakpoint for data capture
    return              	; bank is full, return to main
 
 end                    	; end of program, quit assembling