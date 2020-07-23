;
; Practica5.asm
;
; Created: 19/06/2020 05:10:37 p. m.
;
; Replace with your application code
.ORG 0X00
JMP RESET
.ORG 0X1C
JMP TIM0_COMPA
RESET:
	LDI R16, 0X40
	STS ADMUX, R16	//CONFIGURACION ADC 5V INTERNO
	LDI R16, 0XFF
	OUT DDRD, R16
	OUT DDRB, R16
	LDI R16, 0X07
	STS ADCSRA, R16
	LDI R16, 0X01
	STS DIDR0, R16 
	ldi r16, high(RAMEND); Main program start     
	out SPH,r16 ; Set Stack Pointer to top of RAM     
	ldi r16, low(RAMEND)     
	out SPL,r16
	SEI
    ldi r22,0x00    //COM0B1, WGM01, WGM00
    out TCCR0A,r22  // 00100011
    ldi r22,0x03     //WGM02, CS00 00001011
    out TCCR0B,r22   //
	LDI R16, 255
	OUT OCR0A, R16
	LDI R16, 0X02
	STS TIMSK0, R16

CONVER: //Compuerta OR
	CLR r24
	LDI R17, 0b11000000
	LDS R18, ADCSRA
	OR R18, R17
	STS ADCSRA, R18

ADCDATA:
	LDS R17, ADCSRA	//LEER VALORES ANALOGICOS
	SBRS R17, 4		//CHECA SI LA CONVESION YA SE COMPLETO (ADIF - bit #4)
	RJMP ADCDATA	
	LDS R18, ADCL	//SI LA CONVERSION YA SE COMPLETO, LEEMOS EL DATO EN ADCL
	LDS R19, ADCH   //SI LA CONVERSION YA SE COMPLETO, LEEMOS EL DATO EN ADCL
	//-------------- Multiplicar por 5
	LDI r20, 0x05 ;Factor
	MUL r18, r20
	MOV r22, r0
	MOV r3, r1
	MUL r20, r19
	ADD r3, r0
	MOV r23, r3
	LDI r20, 0xE8
	LDI r21, 0x03
		//----------------	División
DIV:
	MOVW r2, r22; NUMERADORES
	MOVW r4, r20; DENOMINADORES
	CLR r0
	CLR r1
	CLR r8
	LDI r25, 0x01
	COUNT:
		SUB r2, r4	
		SBC r3, r5
		BRLT OK
		CP r3, r5
		ADD r0, r25
		BRCS INCREMENTARR1
		RJMP TESTR3
	INCREMENTARR1:
		INC R1
		RJMP TESTR3
	TESTR3:
		TST r3
		BREQ TESTR2
		MOVW r6,r2		
		SUB r6, r4	
		SBC r7, r5
		SBC r8,r8
		BRLT OK
		RJMP COUNT
	TESTR2:
		TST r2
		BREQ OK
		MOVW r6,r2		
		SUB r6, r4	
		SBC r7, r5
		SBC r8,r8
		BRLT OK
		RJMP COUNT
//---------Selector de digito para imprimir
	OK:	
		TST R0
		BREQ CERO
		MOV R27, R0
		CPI R27, 0X01
		BREQ UNO
		CPI R27, 0X02
		BREQ DOS
		CPI R27, 0X03
		BREQ TRES
		CPI R27, 0X04
		BREQ CUATRO
		CPI R27, 0X05
		BREQ CINCO
		CPI R27, 0X06
		BREQ SEIS
		CPI R27, 0X07
		BREQ SIETE
		CPI R27, 0X08
		BREQ OCHO
		CPI R27, 0X09
		BREQ NUEVE
OUTPUT:	
		ADD R24, R25
		CPI R24, 0X01
		BREQ CIEN
		CPI R24, 0X02
		BREQ DIEZ
		CPI R24, 0X03
		BREQ UNIDAD
SETDEN:	//---- cuando regresa aqui el siguiente denominador ya esta decidido
		CPI R24, 0X04
		BREQ CON		
		MOVW R22, R2
		RJMP DIV	
		//-------pregunta si el digito lleva punto como en el primero de la izquierda
QPUNTO:	
		TST r24
		BREQ PUNTO
		RJMP OUTPUT
CON:	//carga a r12 (ultimo digito en ser impreso) y regresa a convertir otra vez
		MOV R12, R22
		RJMP CONVER
CIEN:	// setea el denominador a 100D y guarda el primer digito en r9
		CLR R21
		LDI R20, 0X64
		MOV R9, R22
		RJMP SETDEN
DIEZ:	// setea el denominador a 10D y guarda el segundo digito en r10
		CLR R21
		LDI R20, 0X0A
		MOV R10, R22
		RJMP SETDEN
UNIDAD:	// setea el denominador a 1D y guarda el primer digito en r11
		CLR R21
		LDI R20, 0X01
		MOV R11, R22
		RJMP SETDEN
//------------Cargar digito a umprimir decidido en el selector

PUNTO:	
		ADD R22, R25
		RJMP OUTPUT
CERO:	
		MOVW R2, R22
		LDI r22, 0xFC
		RJMP QPUNTO
UNO:	
		LDI r22, 0x60
		RJMP QPUNTO
DOS:	
		LDI r22, 0xDA
		RJMP QPUNTO
TRES:	
		LDI r22, 0xF2
		RJMP QPUNTO
CUATRO:	
		LDI r22, 0x66
		RJMP QPUNTO
CINCO:	
		LDI r22, 0xB6
		RJMP QPUNTO
SEIS:	
		LDI r22, 0xBE
		RJMP QPUNTO
SIETE:	
		LDI r22, 0xE0
		RJMP QPUNTO
OCHO:	
		LDI r22, 0xFE
		RJMP QPUNTO
NUEVE:	
		LDI r22, 0xE6
		RJMP QPUNTO
//--------Subrrutina de la interrupción de timer0 cuando compara con OCR0A
TIM0_COMPA:
	CLR R29
	CPI R28, 0X00
	BREQ PRINT1
	CPI R28, 0X01
	BREQ PRINT2
	CPI R28, 0X02
	BREQ PRINT3
	CPI R28, 0X03
	BREQ PRINT4
EXIT:
	RETI
PRINT1:
		OUT PORTD, R29
		OUT PORTD, r9
		OUT PORTB, r28
		INC R28
		RJMP EXIT
PRINT2:
		OUT PORTD, R29
		OUT PORTD, r10
		OUT PORTB, r28
		INC R28
		RJMP EXIT
PRINT3:
		OUT PORTD, R29
		OUT PORTD, r11
		OUT PORTB, r28
		INC R28
		RJMP EXIT
PRINT4:
		OUT PORTD, R29
		OUT PORTD, r12
		OUT PORTB, r28
		CLR R28
		RJMP EXIT