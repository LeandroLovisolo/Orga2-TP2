; void waves_c (
;   unsigned char *src,
;   unsigned char *dst,
;   int m,
;   int n,
;   int row_size,
;   float x_scale,
;   float y_scale,
;   float g_scale
; );

; Parámetros:
;   rdi = src
;   rsi = dst
;   rdx = m
;   rcx = n
;   r8 = row_size
;   xmm0 = x_scale
;   xmm1 = y_scale
;   xmm2 = g_scale

%define Tiene_Ultimo_Tramo 1
%define No_Tiene_ultimo_tramo 0

extern waves_c

global waves_asm

section .rodata

dos: 2.0, 2.0, 2.0, 2.0
pi: DD 3.14159265359, 3.14159265359, 3.14159265359, 3.14159265359
ochenta: DD 80.0, 80.0, 80.0, 80.0

section .text

waves_asm:
	PUSH rbp 			; Alineado
	MOV rbp,rsp
	PUSH rbx 			; Desalineado
	PUSH r12 			; Alineado
	PUSH r13 			; Desalineado
	PUSH r14 			; Alineado
	PUSH r15 			; Desalineado

	; ////////////////////////////////////////////////////////////////////////////////
	; //////////////////////// SETEO DATOS DE USO GENERAL ////////////////////////////
	; ////////////////////////////////////////////////////////////////////////////////

	XOR r12,r12 		; r12 <- i
	XOR r13,r13 		; r13 <- j

	; Harmo registros con repeticiones de x_escale, y_escale y g_escale y 2 para procesar en paralelo
	SHUFPS xmm0,xmm0,0  ; obtengo 4 doubleword's con el contenido de x_escale en xmm0
	SHUFPS xmm1,xmm1,0	; obtengo 4 doubleword's con el contenido de y_escale en xmm1
	SHUFPS xmm2,xmm2,0	; obtengo 4 doubleword's con el contenido de g_escale en xmm2
	MOVDQU xmm3,[pi] 	; obtengo 4 doubleword's con pi
	MOVDQU xmm4,[dos]	; obtengo 4 doubleword's con 2

	
	; xmmo <- x_escale,x_escale,x_escale,x_escale
	; xmm1 <- y_escale,y_escale,y_escale,y_escale
	; xmm2 <- g_escale,g_escale,g_escale,g_escale
	; xmm3 <- pi,pi,pi,pi 

	;//////////////////// SETEO LOS CONTADORES DEL LOOP //////////////////////////////////

	; seteo el rcx para que sepa cuantas vueltas hacer
	MOV rcx,rdx 		; rcx <- m

	; obtengo la cantidad de iteraciones de 16 bytes que puedo hacer en una misma fila
	MOV  r14d,16
	MOV eax,ecx
	IDIV r14d 			; divido n/16
	MOV r14d,eax 		; r14d <- parte entera de n/16
	MOV r10d,r14d 		; r10d <- parte entera de n/16 en esta variable voy a ir iterando

	; r10d <- [n/16]
	
	; me fijo si queda un tramo mas por recorrer luego de las iteraciones de 16 bytes
	MOV rbx,No_Tiene_ultimo_tramo
	CMP edx,0
	JE .ciclo

	; si no salto es porque queda un tramo aparte para recorrer
	MOV r15d,16
	SUB r15d,edx 				; r15d <- 16 - (resto de n/16)
	MOV rbx,Tiene_Ultimo_Tramo 	; seteo el flag rbx para indicar que si hay un ultimo tramo

	; r15d <- 16 - (resto de n/16)

	; lo primero que miro es si hay algo que recorrer, si es la imagen vacia no tiene sentido recorrerla
	CMP rcx,0
	JE .fin

	.ciclo: 	; este ciclo funciona con un LOOP

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////// OBTENGO Y DESEMPAQUETO LOS DATOS ////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; obtengo los datos de la memoria
		MOVDQU xmm5,[rdi] 		; muevo los 16 bytes siguientes a xmm5
		
		; desempaqueto de Byte a Word
		MOVDQU xmm7,xmm5 		; hago una copia para el desempaquetamiento
		XOR xmm9,xmm9 			; lo seteo en 0 para utilizarlo en el desempaquetamiento
		PUNPCKLBW xmm6,xmm9 	
		PUNPCKHBW xmm7,xmm9

		; desempaqueto de Word a Doubleword
		MOVDQU xmm6,xmm5
		MOVDQU xmm8,xmm7
		PUNPCKLWD xmm5,xmm9
		PUNPCKHWD xmm6,xmm9
		PUNPCKLWD xmm7,xmm9
		PUNPCKHWD xmm8,xmm9

		; xmm5 <- byte 1, byte 2, byte 3, byte 4
		; xmm6 <- byte 5, byte 6, byte 7, byte 8
		; xmm7 <- byte 9, byte 10, byte 11, byte 12
		; xmm8 <- byte 13, byte 14, byte 15, byte 16

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////// EMPAQUETO TODOS LOS j/80 DE CADA PIXEL ////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		;// ACA FALTA CARGAR BIEN TODOS LOS J
		
		PUSH rcx
		MOV rcx,8
		MOV r11d,r13d
		MOV r10d,r13d
		MOV r9d,r13d
		ADD r13d,4
		ADD r11d,8
		ADD r10d,12
		ADD r9d,16
		PXOR xmm9
		PXOR xmm10
		PXOR xmm11
		PXOR xmm12
		PXOR xmm13
		PXOR xmm14
		.ciclo2

			MOVD xmm11,r13d 	; muevo el j actual en la parte baja de xmm12
			MOVD xmm12,r11d 	; muevo el j+4 actual en la parte baja de xmm13

			; junto todo en xmm10 y xmm11
			POR xmm9,xmm11
			POR xmm10,xmm12

			DEC r13d			; decremento j actual
			DEC r11d 			; decrementro j+4 actual

			PSLLDQ xmm9,4 		; muevo lo datos a la prox parte mas alta del registro para poner el j decrementado en la parte baja del mismo
			PSLLDQ xmm10,4		; muevo lo datos a la prox parte mas alta del registro para poner el j+4 decrementado en la parte baja del mismo
		
		LOOP .ciclo2
		POP rcx
		; xmm9-xmm10 <- j,j+1,j+2,...,j+16
		
		MOVDQU xmm11,[ochenta]
		DIVPS xmm9,xmm11
		DIVPS xmm10,xmm11
		; xmm9-xmm10 <- j/80,(j+1)/80,(j+2)/80,...,(j+16)/80


		; ////////////////////////////////////////////////////////////////////////////////
		; //////////////////////// SIN_TAYLOR PARA LOS j/80 //////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////


		; // ADAPTAR LOS CMBIOS QUE DEBO HACER EN LA SECCION ANTERIOR A ESTA SECCION
		
		; xmm3 <- pi*2
		MULPS xmm3,xmm4

		; xmm11-xmm12 <- (j/80)/2*pi
		MOV xmm11,xmm9
		MOV xmm12,xmm10
		DIVPS xmm11,xmm3
		DIVPS xmm12,xmm3

		; xmm11-xmm12 <- parte entera de (j/80)/2*pi
		CVTTPS2DQ xmm11,xmm11 		; esta funcion convierte un punto flotante de simple precision en un integer truncando
		CVTTPS2DQ xmm12,xmm12

		; xmm11-xmm12 <- xmm11-xmm12*2*pi
		MULPS xmm11,xmm3
		MULPS xmm12,xmm3

		; xmm13-xmm14 <- xmm11-xmm12
		MOVDQU xmm13,xmm9
		MOVDQU xmm14,xmm10

		; xmm13-xmm14 <- x - xmm11-xmm12
		SUBPS xmm13,xmm11
		SUBPS xmm14,xmm12

		;xmm3 <- pi
		DIVPS xmm3,xmm4

		; xmm9-xmm10 <- xmm13-xmm14 - pi
		MOVDQU xmm9,xmm13
		MOVDQU xmm10,xmm14


	


	LOOP .ciclo
	








.fin:
	POP r15
	POP r14
	POP r13
	POP r12
	POP rbx
	POP rbp
	RET