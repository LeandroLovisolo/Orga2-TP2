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

pi: DD 3.14159265359, 3.14159265359, 3.14159265359, 3.14159265359
dos: DD 2.0, 2.0, 2.0, 2.0
ocho: DD 8.0, 8.0, 8.0, 8.0
jotas1: DD 0.0, 1.0, 2.0, 3.0
jotas2: DD 4.0, 5.0, 6.0, 7.0
jotas3: DD 8.0, 9.0, 10.0, 11.0
jotas4: DD 12.0, 13.0, 14.0, 15.0
seis: DD 6.0, 6.0, 6.0, 6.0
cientoVeinte: DD 120.0, 120.0, 120.0, 120.0
cincoMilCuarenta: DD 5040.0, 5040.0, 5040.0, 5040.0

section .text

waves_asm:
	PUSH rbp			; Alineado
	MOV rbp,rsp
	PUSH rbx 			; Desalineado
	PUSH r12 			; Alineado
	PUSH r13 			; Desalineado
	PUSH r14 			; Alineado
	PUSH r15 			; Desalineado

	
	; ////////////////////////////////////////////////////////////////////////////////
	; ///////////// PUSHEO DATOS QUE USARE LUEGO PARA LIBERAR REGISTROS //////////////
	; ////////////////////////////////////////////////////////////////////////////////

	PUSH xmm0
	PUSH xmm1
	PUSH xmm2


	; ////////////////////////////////////////////////////////////////////////////////
	; //////////////////////// SETEO DATOS DE USO GENERAL ////////////////////////////
	; ////////////////////////////////////////////////////////////////////////////////

	XOR r12,r12 		; r12 <- i0
	XOR r13,r13 		; r13 <- j0

	MOVDQU xmm0,[pi] 	; xmm0 <- pi,pi,pi,pi
	MOVDQU xmm1,[dos]	; xmm1 <- 2,2,2,2

	; //////////////////// STEO LOS CONTADORES DEL LOOP /////////////////////////////

	; ############ salvo valores hasta terminar de setear los datos #################
	MOV r9,rcx 			; r9 <- n

	; ############ seteo rcx para indicarle cuantas vueltas iterar ##################
	MOV rcx,rdx 		; rcx <- m

	; obtengo la cantidad de iteraciones de 16 byte que puedo hacer en una misma fila 
	; sin pasarme
	MOV r14,16
	XOR rdx,rdx
	MOV rax,r9
	IDIV r14 			; divido n/16
	MOV r14,rax 		; r14 <- [n/16]
	MOV r10,r14 		; r10 <- [n/16], ---- en esta variable voy a ir iterando ----

	; me fijo si queda un tramo mas por recorrer luego de las iteraciones de 16 bytes
	MOV rbx,No_Tiene_ultimo_tramo
	CMP rdx,0
	JE .ciclo

	; ############ si no salto es porque queda un tramo aparte para recorrer #########
	MOV r15,16
	SUB r15,rdx 				; r15d <- 16 - (n mod 16)
	MOV rbx,Tiene_Ultimo_Tramo 	; seteo el flag rbx indicando que si hay un ultimo tramo

	; lo primero que miro es si hay algo que recorrer, si es la imagen vacia no tiene 
	; sentido recorrerla
	CMP rcx,0
	JE .fin

	; ########################## ESTADO DE LOS REGISTROS #############################
	
	; ############# REGISTROS PARA EL LOOP ###########################################
	; rcx <- m
	; r10 <- [n/16]
	; r14 <- [n/16]
	; rbx <- queda_ultimo_tramo o no
	; r15 <- 16 - (n mod 16)

	; ############ REGISTROS DE LA IMAGEN ############################################

	; rdi <- src
   	; rsi <- dst
   	; r8 <- row_size
   	; xmm0 <- pi,pi,pi,pi
	; xmm1 <- 2,2,2,2
	; r12 <- i0
	; r13 <- j0

	; ########### REGISTROS PUSHEADOS ################################################
	
	; xmm0 <- x_escale
	; xmm1 <- y_escale
	; xmm2 <- g_escale

	; ############################ FIN ESTADO DE LOS REGISTROS #######################

	.ciclo:

		; ////////////////////////////////////////////////////////////////////////////////
		; ///////////////// EMPAQUETO TODOS LOS j/80 DE CADA PIXEL ///////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; seteo los j con numeros de 0, ... ,15
		MOVDQU xmm2,[jotas1] ; VER DE COLOCAR ALINEADO LOS DATOS PARA USAR MOVDQA
		MOVDQU xmm3,[jotas2]
		MOVDQU xmm4,[jotas3]
		MOVDQU xmm5,[jotas4]

		; lleno de j's xmm6
		PXOR xmm7,xmm7
		MOVQ xmm6,r13
		MOVDQU xmm7,xmm6
		PSLLDQ xmm7,4
		POR xmm7,xmm6
		PSLLDQ xmm7,4
		POR xmm7,xmm6
		PSLLDQ xmm7,4
		POR xmm7,xmm6

		CVTDQ2PS xmm6,xmm7

		; a los registros con los numeros del 0, ... ,15 les sumo j
		ADDPS xmm2,xmm6
		ADDPS xmm3,xmm6
		ADDPS xmm4,xmm6
		ADDPS xmm5,xmm6


		; ########################## ESTADO DE LOS REGISTROS #############################
	
		; xmm2 <- j, ... ,j+3
		; xmm3 <- j+4, ... ,j+7 	    VER SI REALMENTE EL RESULTADO ES ESTE QUE ENUNCIO
		; xmm4 <- j+8, ... ,j+11
		; xmm5 <- j+12, ... j+15

		; ############################ FIN ESTADO DE LOS REGISTROS #######################

		MOVDQU xmm6,[ocho]

		DIVPS xmm2,xmm6
		DIVPS xmm3,xmm6
		DIVPS xmm4,xmm6
		DIVPS xmm5,xmm6

		; ########################## ESTADO DE LOS REGISTROS #############################
	
		; xmm2 <- j/80, ... ,(j+3)/80
		; xmm3 <- (j+4)/80, ... ,(j+7)/80
		; xmm4 <- (j+8)/80, ... ,(j+11)/80
		; xmm5 <- (j+12)/80, ... (j+15)/80

		; ############################ FIN ESTADO DE LOS REGISTROS #######################

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////// FUNCION DE TAYLOR PARA LOS j/80 /////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; ################################################################################
		; ## HABLO DE LOS REGISTROS COMO UN SOLO NUMERO SABIENDO QUE ESTAN EMPAQUETADOS ##
		; ################################################################################

		MULPS xmm0,xmm1 	; xmm0 <- 2*pi

		; ############################### K = [x/(2*pi)] #################################

		MOVDQU xmm6,xmm2
		MOVDQU xmm7,xmm3
		MOVDQU xmm8,xmm4
		MOVDQU xmm9,xmm5

		DIVPS xmm6,xmm0 	; k <- x/(2*pi)
		DIVPS xmm7,xmm0 	; k <- x/(2*pi)
		DIVPS xmm8,xmm0 	; k <- x/(2*pi)
		DIVPS xmm9,xmm0 	; k <- x/(2*pi)

		; ######################## obtengo la parte entera ###############################
		; VER COMO FUNCIONA LA INSTRUCCION "ROUNDPS"

		CVTTPS2DQ xmm6,xmm6
		CVTTPS2DQ xmm7,xmm7
		CVTTPS2DQ xmm8,xmm8
		CVTTPS2DQ xmm9,xmm9

		CVTDQ2PS xmm6,xmm6
		CVTDQ2PS xmm7,xmm7
		CVTDQ2PS xmm8,xmm8
		CVTDQ2PS xmm9,xmm9

		; ######################### R = x - K*2*pi ######################################

		MULPS xmm6,xmm0 	; k <- k*2*pi
		MULPS xmm7,xmm0 	; k <- k*2*pi
		MULPS xmm8,xmm0 	; k <- k*2*pi
		MULPS xmm9,xmm0 	; k <- k*2*pi

		SUBPS xmm2,xmm6 	; r <- x - k*2*pi
		SUBPS xmm3,xmm7 	; r <- x - k*2*pi
		SUBPS xmm4,xmm8 	; r <- x - k*2*pi
		SUBPS xmm5,xmm9 	; r <- x - k*2*pi

		; ############################### X = R - pi ##################################

		MULPS xmm0,xmm1 	; xmm0 <- pi

		SUBPS xmm2,xmm0 	; x <- r - pi
		SUBPS xmm3,xmm0 	; x <- r - pi
		SUBPS xmm4,xmm0 	; x <- r - pi
		SUBPS xmm5,xmm0 	; x <- r - pi

		; #################### Y = X - X³/6 + X⁵/120 - X⁵/5040 ####################

		; ############################### Y = X  ##################################

		MOVDQU xmm6,xmm2
		MOVDQU xmm7,xmm3
		MOVDQU xmm8,xmm4
		MOVDQU xmm9,xmm5

		; ############################### x³/6 #####################################
		
		MOVDQU xmm10,xmm2
		MOVDQU xmm11,xmm3
		MOVDQU xmm12,xmm4
		MOVDQU xmm13,xmm5

		; x*x = x²
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		; x²*x = x³
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		MOVDQU xmm14,[seis]

		DIVPS xmm10,xmm14
		DIVPS xmm11,xmm14
		DIVPS xmm12,xmm14
		DIVPS xmm13,xmm14

		; ############################ Y = x - x³/6 ################################

		SUBPS xmm6,xmm10
		SUBPS xmm7,xmm11
		SUBPS xmm8,xmm12
		SUBPS xmm9,xmm13

		; ############################### x⁵/120 #####################################


		MOVDQU xmm10,xmm2
		MOVDQU xmm11,xmm3
		MOVDQU xmm12,xmm4
		MOVDQU xmm13,xmm5

		; x²
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		; x²*x² = x⁴
		MULPS xmm10,xmm10 
		MULPS xmm11,xmm11
		MULPS xmm12,xmm12
		MULPS xmm13,xmm13

		; x⁴*x = x⁵
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5


		MOVDQU xmm14,[cientoVeinte]

		DIVPS xmm10,xmm14
		DIVPS xmm11,xmm14
		DIVPS xmm12,xmm14
		DIVPS xmm13,xmm14

		; ########################## Y = x -x³/6 + x⁵/120 ############################

		ADDPS xmm6,xmm10
		ADDPS xmm7,xmm11
		ADDPS xmm8,xmm12
		ADDPS xmm9,xmm13


		; ############################### x⁷/5040 #####################################


		MOVDQU xmm10,xmm2
		MOVDQU xmm11,xmm3
		MOVDQU xmm12,xmm4
		MOVDQU xmm13,xmm5

		; x*x = x²
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		; x²*x² = x⁴
		MULPS xmm10,xmm10
		MULPS xmm11,xmm10
		MULPS xmm12,xmm10
		MULPS xmm13,xmm10

		; x⁴*x = x⁵
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		; x⁵*x = x⁶
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		; x⁶*x = x⁷
		MULPS xmm10,xmm2
		MULPS xmm11,xmm3
		MULPS xmm12,xmm4
		MULPS xmm13,xmm5

		MOVDQU xmm14,[cincoMilCuarenta]

		DIVPS xmm10,xmm14
		DIVPS xmm11,xmm14
		DIVPS xmm12,xmm14
		DIVPS xmm13,xmm14

		; ########################## Y = x -x³/6 + x⁵/120 - x⁷/5040 ############################

		SUBPS xmm6,xmm10
		SUBPS xmm7,xmm11
		SUBPS xmm8,xmm12
		SUBPS xmm9,xmm13

		; ############################# ESTADO DE LOS REGISTROS ##############################

		; xmm6 <- sin_taylor(j/8)
		; xmm7 <- sin_taylor(j+4/8)
		; xmm8 <- sin_taylor(j+12/8)
		; xmm9 <- sin_taylor(j+16/8)

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////// FUNCION DE TAYLOR PARA LOS i/80 /////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		MOVD xmm2,r13
		MOVDQU xmm3,[ochenta]
		DIVPS xmm2,xmm3

		MULPS xmm0,xmm1 	; xmm0 <- 2*pi

		; ############################### K = [x/(2*pi)] #################################

		MOVDQU xmm3,xmm2
		DIVPS xmm3,xmm0 	; k <- x/(2*pi)


		; ######################## obtengo la parte entera ###############################

		CVTTPS2DQ xmm3,xmm3
		CVTDQ2PS xmm3,xmm3

		; ######################### R = x - K*2*pi ######################################

		MULPS xmm3,xmm0 	; k <- k*2*pi
		MOVDQU xmm4,xmm2
		SUBPS xmm4,xmm6 	; r <- x - k*2*pi

		; ############################### X = R - pi ##################################

		DIVPS xmm0,xmm1 	; xmm0 <- pi
		MOVDQU xmm2,xmm4
		SUBPS xmm2,xmm0 	; x <- r - pi

		; #################### Y = X - X³/6 + X⁵/120 - X⁷/5040 ####################

		; ############################### Y = X  ##################################

		MOVDQU xmm3,xmm2

		; ############################### x³/6 #####################################
		
		MOVDQU xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MOVDQU xmm14,[seis]
		DIVPS xmm4,xmm14


		; ############################ Y = x - x³/6 ################################

		SUBPS xmm3,xmm4

		; ############################### x⁵/120 #####################################
		
		MOVDQU xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MOVDQU xmm14,[cientoVeinte]
		DIVPS xmm4,xmm14


		; ############################ Y = x + x⁵/6 ################################

		ADDPS xmm3,xmm4

		; ############################### x⁷/5040 ##################################
		
		MOVDQU xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MULPS xmm4,xmm2
		MOVDQU xmm14,[cincoMilCuarenta]
		DIVPS xmm4,xmm14


		; ############################ Y = x + x⁵/6 - x⁷/5040 #########################

		SUBPS xmm3,xmm4
		PXOR xmm4,xmm4
		MOVDQU xmm4,xmm3
		PSLLDQ xmm4,4
		POR xmm4,xmm3
		PSLLDQ xmm4,4
		POR xmm4,xmm3
		PSLLDQ xmm4,4
		POR xmm4,xmm3

		; ######################## ESTADO DE LOS REGISTROS #############################

		; xmm6 <- sin_taylor(j/8)
		; xmm7 <- sin_taylor(j+4/8)
		; xmm8 <- sin_taylor(j+12/8)
		; xmm9 <- sin_taylor(j+16/8)
		; xmm4 <- sin_taylor(i/8)


		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////////////// PROF DE I,J /////////////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; ##################### HAGO POP DE LOS X_sacale,y_scale,g_scale ###################

		MOVDQU xmm5,xmm1

		POP xmm0
		POP xmm1
		POP xmm2 

		MULPS xmm4,xmm0

		MULPS xmm6,xmm1
		MULPS xmm7,xmm1
		MULPS xmm8,xmm1
		MULPS xmm9,xmm1

		ADDPS xmm6,xmm4
		ADDPS xmm7,xmm4
		ADDPS xmm8,xmm4
		ADDPS xmm9,xmm4

		DIVPS xmm6,xmm1
		DIVPS xmm7,xmm1
		DIVPS xmm8,xmm1
		DIVPS xmm9,xmm1

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////////////// I_dest(i,j) /////////////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		MULPS xmm6,xmm2
		MULPS xmm7,xmm2
		MULPS xmm8,xmm2
		MULPS xmm9,xmm2

		; ################## RECUPERO Y DESEMPAQUETO LOS DATOS DE LAIMAGEN ##############

		MOVDQU xmm2,[rdi] 		; muevo los 16 bytes siguientes a xmm2
		
		; desempaqueto de Byte a Word
		MOVDQU xmm4,xmm2 			; hago una copia para el desempaquetamiento
		PXOR xmm10,xmm10 			; lo seteo en 0 para utilizarlo en el desempaquetamiento
		PUNPCKLBW xmm2,xmm10 	
		PUNPCKHBW xmm4,xmm10

		; desempaqueto de Word a Doubleword
		MOVDQU xmm3,xmm2
		MOVDQU xmm5,xmm4
		PUNPCKLWD xmm2,xmm10
		PUNPCKHWD xmm3,xmm10
		PUNPCKLWD xmm4,xmm10
		PUNPCKHWD xmm5,xmm10

		; convierto a punto flotantes

		CVTDQ2PS xmm2,xmm2
		CVTDQ2PS xmm3,xmm3
		CVTDQ2PS xmm4,xmm4
		CVTDQ2PS xmm5,xmm5

		ADDPS xmm2,xmm6
		ADDPS xmm3,xmm7
		ADDPS xmm4,xmm8
		ADDPS xmm5,xmm9

		; ########################## CONVIERTO A ENTEROS ##################################

		CVTTPS2DQ xmm2,xmm2
		CVTTPS2DQ xmm3,xmm3
		CVTTPS2DQ xmm4,xmm4
		CVTTPS2DQ xmm5,xmm5

		MOVDQU xmm6,xmm2
		MOVDQU xmm7,xmm3
		MOVDQU xmm8,xmm4
		MOVDQU xmm9,xmm5

		; ########################## EMPAQUETO SATURANDO ##################################
		
		; empaqueto de doubleWord a word
		PACKSSDW xmm6,xmm7
		PACKSSDW xmm8,xmm9

		; empaqueto de word a bytes
		PACKSSWB xmm6,xmm8

		; guardo los datos en el destino
		MOVDQU [rsi],xmm6
		
		; ////////////////////////////////////////////////////////////////////////////////
		; ///////////////// configuro la iteración del ciclo /////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////


		DEC r10 	; decremento la cantidad de iteraciones que me faltan para terminar la fila actual

		; me fijo si ya llegue al final de la fila
		CMP r10,0
		JE .termine_iteraciones ; en el caso en que halla llegado al final debo ver si tengo que 
								; recorrer el proximo tramito o no

		; me fijo si mire el ultimo tramo
		CMP r10,-1
		JE .saltear_proxima_linea

		; si no termine las iteraciones entonces solo sumo 16 para pasar al proximo ciclo
	.siguienteCiclo:
		ADD rdi,16
		ADD rsi,16
		ADD r13,16 	
		JMP .finCiclo

		; si termine las iteraciones entonces me fijo si tengo que saltar directamente a la proxima fila o si queda un tramo menor a 16 por recorrer
	.termine_iteraciones:
		CMP rbx,No_Tiene_ultimo_tramo
		JE .saltear_proxima_linea 		; si no hay ultimo tramo salto directamente a la proxima fila a procesar 

		; si no salto es porque puede haber un ultimo tramo a recorrer
		; en tal caso me fijo si ya lo hice o no
		SUB rdi,r15
		SUB rsi,r15
		JMP .finCiclo

	.saltear_proxima_linea:
		MOV r10,r14 		; le vuelvo a cargar la cantidad de iteraciones a realizar en una lina
		ADD rdi,16
		ADD rsi,16	
		LEA rdi,[rdi + r15] ; le cargo el padding
		LEA rsi,[rsi + r15]
		INC r12


.finCiclo:

		LOOP .ciclo


.fin:
	POP r15
	POP r14
	POP r13
	POP r12
	POP rbx
	POP rbp
	RET