;ESTA VERSION CUENTA HASTA 9,59,99 MINUTOS.
;INCLUYE UN BOTON DE START/STOP.
;INCLUYE UN BOTON DE RESET (PUESTA A 0).
;ADMITE LA CARGA DEL REGISTRO DIG4 (EQU 23H) POR PUERTO SERIE.



LIST P= 16F887
INCLUDE P16F887.INC

; CONFIG1
; __config 0xFFE1
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


DIG1	EQU	20h
DIG2	EQU	21h
DIG3	EQU	22h
DIG4	EQU	23h
DIG5	EQU	24H
CIEN	EQU	25H
DIEZ	EQU	26H
ROTA	EQU	27H
RECIB	EQU	28H
TRANS	EQU	29H
W_TEMP	EQU	30H
S_TEMP	EQU 31h
AUX		EQU 32h

ORG		0X00
GOTO	START

ORG		0X04
GOTO	RSI

ORG		0X05


START	CLRF 	DIG1
		CLRF	DIG2
		CLRF	DIG3
		CLRF	DIG4
		CLRF	DIG5
		CLRF	CIEN
		CLRF	DIEZ
		CLRF	ROTA
		CLRF	RECIB
		CLRF	TRANS
		CLRF	W_TEMP
		CLRF	S_TEMP
		CLRF	TMR0

		CLRF	STATUS			; RESET DE STATUS
		BCF		STATUS,Z		; 
		BSF		STATUS,RP0
		MOVLW	B'00000000'
		MOVWF	TRISD
		MOVLW	B'11100000'
		MOVWF	TRISA
		MOVLW	B'00000111'		; PRESCALER 256
		MOVWF	OPTION_REG
		MOVLW	B'11011000'		; GIE=1 PEIE=1 T0IE=0 INTE=1 RBIE=1
		MOVWF	INTCON			; 
		BSF		PIE1,RCIE		; INTERRUPCIONES POR RECEPCION (PEIE DEBE SER =1)

		BSF		STATUS,RP0		;
		BSF		STATUS,RP1		; SELECCION DEL BANCO 3
		MOVLW	B'00000000'		;
		MOVWF	ANSELH			; PUERTO B COMO ENTRADAS DIGITALES	
		BCF		STATUS,RP1      ; SELECCION DEL BANCO 1

		MOVLW	B'11111111'		; PUERTO B COMO ENTRADA
		MOVWF	TRISB			;
		
		MOVLW	B'11111111'		; RESISTENCIAS DE PULL-UP HABILITADAS
		MOVWF	WPUB			;
		
		BANKSEL IOCB			; INTERRUPCION POR CAMBIOS EN PORTB ( ADEMAS RBIE DEBE SER =1)
		MOVLW   30h				;
		MOVWF   IOCB			;
		
		
		
		

		;CONFIGURACION UART
		;-------------------------------------------------------
		;REGISTRO TXSTA
		BSF		STATUS,RP0
		BCF		STATUS,RP1
		MOVLW	B'00100100'
		MOVWF	TXSTA		;BRGH=1 PARA CRISTAL DE 4 MHZ
		;CONFIG DE BAUDRATE A 9600
		MOVLW	D'25'
		MOVWF	SPBRG
		;CONFIG DEL REGISTRO RCSTA	(RECEIVE STATUS & CONTROL REG)
		BCF		STATUS,RP0  
		MOVLW	B'10010000'
		MOVWF	RCSTA
		
		;CONFIGURACION PARA EL REGISTRO BAUDCTL 
		BSF 	STATUS,RP0
		BSF		STATUS,RP1
		MOVLW	B'01000000'
		MOVWF	BAUDCTL
		BCF		STATUS,RP1
		BCF		STATUS,RP0
	
		;NUMEROS FICTICIOS
		MOVLW	D'0'
		MOVWF	DIG1
		MOVLW	D'0'
		MOVWF	DIG2
		MOVLW	D'0'
		MOVWF	DIG3
		MOVLW	D'0'
		MOVWF	DIG4
		MOVLW	D'216'
		MOVWF	TMR0

EMPE	MOVLW	B'00010000'
		MOVWF	ROTA
		CLRF	PORTA
		MOVLW	DIG1
		MOVWF	FSR
DISP	CLRF	PORTD
		MOVF	ROTA,W
		MOVWF	PORTA

		MOVF	INDF,0
		CALL	TABLA
		MOVWF	PORTD
		CALL	RETARDO
		CLRF	PORTD
		BTFSC	ROTA,0
		GOTO	EMPE
		BCF		STATUS,C
		RRF		ROTA,1
		INCF	FSR,1
		GOTO	DISP


TABLA	ADDWF	PCL,1
;		ORDEN DE LOS SEGMENTOS .GFEDCBA
		RETLW	B'00111111' ;0
		RETLW	B'00000110'	;1
		RETLW	B'01011011'	;2
		RETLW	B'01001111'	;3
		RETLW	B'01100110'	;4
		RETLW	B'01101101'	;5
		RETLW	B'01111101'	;6
		RETLW	B'00000111'	;7
		RETLW	B'01111111'	;8
		RETLW	B'01101111'	;9

RSI		CALL	SALVA_E
		
		BTFSC	INTCON,INTF		; INT POR RBO
		CALL	BOTONSS			; SI

		BTFSC	INTCON,T0IF		; INT POR TMR0
		CALL	CENT			; SI
		
		BTFSC	INTCON,RBIF		; INT POR RB4-7
		CALL    RESETEA			; SI
		
		BTFSC	PIR1,RCIF		; INT POR RECEPCION
		CALL	RECIBE			; SI


SALIR	CALL	RECUP_E
		RETFIE

SALVA_E	MOVWF	W_TEMP
		SWAPF	STATUS,W
		MOVWF	S_TEMP
		RETURN

RECUP_E	SWAPF	S_TEMP,W
		MOVWF	STATUS
		SWAPF	W_TEMP,F
		SWAPF	W_TEMP,W
		RETURN

BOTONSS	BTFSS	INTCON,T0IE     ;TMR0 CORRIENDO
		GOTO	PARADO			;NO
		GOTO	PREND			;SI

PARADO	BCF		INTCON,INTF
		BSF		INTCON,T0IE		;HABILITA INTERRUP POR TMR0 (PARA EL CRONOMETRO)
		RETURN

PREND	BCF		INTCON,INTF
		BCF		INTCON,T0IE
		RETURN

RECIBE	BCF		PIR1,RCIF		; SE BAJA EL FLAG DE INT POR RECEPCION
		MOVF	RCREG,W	
		MOVWF   AUX
		MOVLW	0Fh
		ANDWF   AUX,W
		MOVWF   DIG3
		MOVF	RCREG,W
		MOVWF   AUX
		MOVLW	B'11110000'
		ANDWF	AUX,F
		SWAPF	AUX,W
		MOVWF	DIG2
		CLRF	DIG5
		CLRF    DIG4
		CLRF 	DIG1
		RETURN

RESETEA 
		BTFSS	PORTB,5
		GOTO	RESET_14
		BTFSS	PORTB,4
		GOTO	RESET_24
		MOVF	PORTB, W
		BCF 	INTCON, RBIF
		GOTO 	SALIR
		
RESET_24
		CALL	PARADO
		MOVLW   D'2'
		MOVWF   DIG2
		MOVLW	D'4'
		MOVWF	DIG3
		CLRF	DIG1
		CLRF	DIG4
		CLRF	DIG5
		MOVF	PORTB, W
		BCF 	INTCON, RBIF

		RETURN
		
RESET_14
		CALL	PARADO
		MOVLW   D'1'
		MOVWF   DIG2
		MOVLW	D'4'
		MOVWF	DIG3
		CLRF	DIG1
		CLRF	DIG4
		CLRF	DIG5
	 	MOVF	PORTB, W
		BCF 	INTCON, RBIF
		RETURN
		
		
CENT	MOVLW	D'216'
		MOVWF	TMR0
		BCF		INTCON,T0IF
		DECF	DIG5,F
		MOVLW	B'11111111'
		SUBWF	DIG5,W
		BTFSS	STATUS,Z
		RETURN
		
		
		
DECIMA	MOVLW	D'9'
		MOVWF	DIG5
		DECF	DIG4
		MOVLW	B'11111111'
		SUBWF	DIG4,W
		BTFSS	STATUS,Z
		RETURN
		
SEGUNDO MOVLW	D'9'
		MOVWF	DIG4
		DECF	DIG3
		MOVLW	B'11111111'
		SUBWF	DIG3,W
		BTFSS	STATUS,Z
		RETURN

DISEG	MOVLW	D'9'	
		MOVWF	DIG3
		DECF	DIG2
		MOVLW	B'11111111'
		SUBWF	DIG2,W
		BTFSS	STATUS,Z
		RETURN

MIN		MOVLW	D'5'
		MOVWF	DIG2
		DECF	DIG1
		MOVLW	B'11111111'
		SUBWF	DIG1,W
		BTFSS	STATUS,Z
		RETURN
		CLRF	DIG1
		CLRF	DIG2
		CLRF	DIG3
		CLRF	DIG4
		CLRF	DIG5
		GOTO	PREND

RETARDO	MOVLW	D'8'
		MOVWF	CIEN
		MOVLW	D'2'
		MOVWF	DIEZ
L1		NOP
		NOP
		NOP
		DECFSZ	CIEN
		GOTO	L1
		DECFSZ	DIEZ
		GOTO	L1
		RETURN

		END