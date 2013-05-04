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
jotas1: DD 0.0, 1.0, 2.0, 3.0
jotas2: DD 4.0, 5.0, 6.0, 7.0
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
	; //////////////////////// SETEO DATOS DE USO GENERAL ////////////////////////////
	; ////////////////////////////////////////////////////////////////////////////////

	XOR r12,r12 		; r12 <- i0
	XOR r13,r13 		; r13 <- j0

	MOVDQU xmm3,[pi] 				; xmm0 <- pi,pi,pi,pi
	MOVDQU xmm4,[dos]				; xmm1 <- 2.0,2.0,2.0,2.0
	MOVDQU xmm5,[jotas1] 			; xmm5 <- 3,2,1,0
	MOVDQU xmm6,[jotas2] 			; xmm6 <- 7,6,5,4
	MOVDQU xmm7,[seis] 				; xmm7 <- 6.0,6.0,6.0,6.0
	MOVDQU xmm8,[cientoVeinte] 		; xmm8 <- 120.0,120.0,120.0,120.0
	MOVDQU xmm9,[cincoMilCuarenta] 	; xmm9 <- 5040.0,5040.0,5040.0,5040.0

	; ##################### REPITO LOS _SCALE EN LOSREGISTROS ######################
	
	SHUFPS xmm0,xmm0,0 	; xmm0 <- x_scale,x_scale,x_scale,x_scale
	SHUFPS xmm1,xmm1,0 	; xmm1 <- y_scale,y_scale,y_scale,y_scale
	SHUFPS xmm2,xmm2,0 	; xmm2 <- g_scale,g_scale,g_scale,g_scale

	; //////////////////// STEO LOS CONTADORES DEL LOOP /////////////////////////////

	; ############ salvo valores hasta terminar de setear los datos #################
	
	MOV r9,rcx 			; r9 <- n

	; ############ seteo rcx para indicarle cuantas vueltas iterar ##################
	
	MOV rcx,rdx 		; rcx <- m

	; obtengo la cantidad de iteraciones de 8 byte que puedo hacer en una misma fila 
	; sin pasarme
	MOV r14,8
	XOR rdx,rdx
	XOR rax,rax
	MOV rax,r9  		; rax <- n
	IDIV r14 			; divido n/8
	MOV r14,rax 		; r14 <- [n/8]
	MOV r10,r14 		; r10 <- [n/8], ---- en esta variable voy a ir iterando ----

	; cargo el paddin en r8
	SUB r8,r9 			; r8 <- row_size - n

	; me fijo si queda un tramo mas por recorrer luego de las iteraciones de 16 bytes
	MOV rbx,No_Tiene_ultimo_tramo
	MOV r15,0 					; por las dudas si no tiene ultimo tramo le pongo 0
	CMP rdx,0
	JE .ciclo

	; ########## si no salto es porque queda un tramo aparte para recorrer ##########
	MOV r15,rdx 				; r15d <- resto de [n/8]
	MOV rbx,Tiene_Ultimo_Tramo 	; seteo el flag rbx indicando que hay un ultimo tramo

	; ############################ EMPIEZA EL CICLO #################################

	; lo primero que miro es si hay algo que recorrer, si es la imagen vacia no tiene 
	; sentido recorrerla, se que si tiene una fila minimo tiene 16 bytes. ENUNCIADO TP2
	CMP rcx,0
	JE .fin

	; ########################## ESTADO DE LOS REGISTROS #############################
	
	; ############# REGISTROS PARA EL LOOP ###########################################
	; rcx <- m
	; r10 <- [n/8]
	; r14 <- [n/8]
	; rbx <- queda_ultimo_tramo o no
	; r15 <- resto de [n/8]
	; r8  <- row_size - n

	; ############ REGISTROS DE LA IMAGEN ############################################

	; rdi <- src
   	; rsi <- dst
   	; r8 <- row_size
	; r12 <- i0
	; r13 <- j0
	; xmm0 <- x_scale,x_scale,x_scale,x_scale
	; xmm1 <- y_scale,y_scale,y_scale,y_scale
	; xmm2 <- g_scale,g_scale,g_scale,g_scale
   	; xmm3 <- pi,pi,pi,pi
	; xmm4 <- 2.0,2.0,2.0,2.0
	; xmm5 <- 3.0,2.0,1.0,0.0
	; xmm6 <- 7.0,6.0,5.0,4.0
	; xmm7 <- 6.0,6.0,6.0,6.0
	; xmm8 <- 120.0,120.0,120.0,120.0
	; xmm9 <- 5040.0,5040.0,5040.0,5040.0

	; ############################ FIN ESTADO DE LOS REGISTROS #######################

	.ciclo:

		; ////////////////////////////////////////////////////////////////////////////////
		; ///////////////// EMPAQUETO TODOS LOS j/80 DE CADA PIXEL ///////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; obtengo los j
		MOVQ xmm10,r13  		; xmm10 <- basura,basura,basura,j
		SHUFPS xmm10,xmm10,0  	; xmm10 <- j,j,j,j
		CVTDQ2PS xmm10,xmm10 		; convierto los J's a punto flotante de simple presicion
		MOVDQU xmm11,xmm10 		; xmm11 <- j.0,j.0,j.0,j.0

		; a registros de j les sumo 0, ... ,7
		ADDPS xmm10,xmm5 		; xmm10 <- (j+3).0, ... ,j.0
		ADDPS xmm11,xmm6 		; xmm11 <- (j+7).0, ... ,(j+4).0

		; ######################### DIVIDO POR 2 HASTA DIVIDIR POR 8 #######################

		DIVPS xmm10,xmm4
		DIVPS xmm10,xmm4
		DIVPS xmm10,xmm4 		; xmm10 <- (j+4).0/8.0, ... , j.0/8.0
		DIVPS xmm11,xmm4
		DIVPS xmm11,xmm4
		DIVPS xmm11,xmm4 		; xmm1 <- (j+7).0/8.0, ... , (j+4).0/8.0
 

		; ########################## ESTADO DE LOS REGISTROS #############################
	
		; xmm10 <- ; xmm10 <- (j+4).0/8.0, ... , j.0/8.0
		; xmm11 <- ; xmm1 <- (j+7).0/8.0, ... , (j+4).0/8.0

		; ############################ FIN ESTADO DE LOS REGISTROS #######################

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////// FUNCION DE TAYLOR PARA LOS j/80 /////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; ############################### K = [x/(2*pi)] #################################

		MOVDQU xmm12,xmm10
		MOVDQU xmm13,xmm11

		DIVPS xmm12,xmm4 	; xmm12 <- x.0/2.0
		DIVPS xmm13,xmm4 	; xmm13 <- x.0/2.0
		
		DIVPS xmm12,xmm3 	; xmm12 <- x.0/2.0*pi
		DIVPS xmm13,xmm3 	; xmm13 <- x.0/2.0*pi 

		; haciendolo por separado x/2*pi = (x/2)/pi no modifico las mascaras evitando
		; aumentar errores en futuros pixeles 


		; ######################## obtengo la parte entera ###############################
		; VER COMO FUNCIONA LA INSTRUCCION "ROUNDPS"

		CVTTPS2DQ xmm12,xmm12
		CVTTPS2DQ xmm13,xmm13


		CVTDQ2PS xmm12,xmm12
		CVTDQ2PS xmm13,xmm13

		; ######################### R = x - K*2*pi ######################################

		MULPS xmm12,xmm3 	; xmm12 <- k*pi
		MULPS xmm13,xmm3	; xmm13 <- k*pi

		MULPS xmm12,xmm4 	; xmm12 <- k*2*pi
		MULPS xmm13,xmm4	; xmm13 <- k*2*pi


		SUBPS xmm10,xmm12 	; xmm10 <- x - k*2*pi
		SUBPS xmm11,xmm13 	; xmm11 <- x - k*2*pi

		; ############################### X = R - pi ##################################

		SUBPS xmm10,xmm3 	; x <- r - pi
		SUBPS xmm11,xmm3 	; x <- r - pi

		; #################### Y = X - X³/6 + X⁵/120 - X⁵/5040 ####################

		; ############################### Y = X  ##################################

		MOVDQU xmm12,xmm10
		MOVDQU xmm13,xmm11

		; ############################### x³/6 #####################################
		
		MOVDQU xmm14,xmm10
		MOVDQU xmm15,xmm11

		; x*x = x²
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x²*x = x³
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x³/6
		DIVPS xmm14,xmm7
		DIVPS xmm15,xmm7

		; ############################ Y = x - x³/6 ################################

		SUBPS xmm12,xmm14
		SUBPS xmm13,xmm15


		; ############################### x⁵/120 #####################################


		MOVDQU xmm14,xmm10
		MOVDQU xmm15,xmm11

		; x*x = x²
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x²*x² = x^4
		MULPS xmm14,xmm14
		MULPS xmm15,xmm15

		; x^4*x = x⁵
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x⁵/120
		DIVPS xmm14,xmm8
		DIVPS xmm15,xmm8



		; ########################## Y = x -x³/6 + x⁵/120 ############################

		ADDPS xmm12,xmm14
		ADDPS xmm13,xmm15


		; ############################### x⁷/5040 #####################################


		MOVDQU xmm14,xmm10
		MOVDQU xmm15,xmm11

		; x*x = x²
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x²*x² = x^4
		MULPS xmm14,xmm14
		MULPS xmm15,xmm15

		; x^4*x = x⁵
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x^5*x = x6
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x^6*x = x⁷
		MULPS xmm14,xmm10
		MULPS xmm15,xmm11

		; x⁷/5040
		DIVPS xmm14,xmm9
		DIVPS xmm15,xmm9

		; ########################## Y = x -x³/6 + x⁵/120 - x⁷/5040 ############################

		SUBPS xmm12,xmm14
		SUBPS xmm13,xmm15

		; ############################# ESTADO DE LOS REGISTROS ##############################

		
		; xmm12 <- sin_taylor((j+3).0/8.0), sin_taylor((j+2).0/8.0), sin_taylor((j+1).0/8.0), sin_taylor((j).0/8.0),
		; xmm13 <- sin_taylor((j+7).0/8.0), sin_taylor((j+6).0/8.0), sin_taylor((j+5).0/8.0), sin_taylor((j+4).0/8.0),

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////// FUNCION DE TAYLOR PARA LOS i/80 /////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		MOVQ xmm10,r12 		; xmm10 <- basura,basura,basura,i
		SHUFPS xmm10,xmm10,0 	; xmm10 <- i,i,i,i
		CVTDQ2PS xmm10,xmm10 	; xmm10 <- i.0,i.0,i.0,i.0
		
		DIVPS xmm10,xmm4 		; xmm10 <- i.0/2.0,i.0/2.0,i.0/2.0,i.0/2.0
		DIVPS xmm10,xmm4 		; xmm10 <- i.0/4.0,i.0/4.0,i.0/4.0,i.0/4.0
		DIVPS xmm10,xmm4 		; xmm10 <- i.0/8.0,i.0/8.0,i.0/8.0,i.0/8.0

		; ############################### K = [x/(2*pi)] #################################

		MOVDQU xmm11,xmm10
		DIVPS xmm11,xmm3 		; xmm11 <- x/pi
		DIVPS xmm11,xmm4 		; xmm11 <- x/2*pi


		; ######################## obtengo la parte entera ###############################
		; VER SI UTILIZO LA FUNCION ROUNDPS

		CVTTPS2DQ xmm11,xmm11
		CVTDQ2PS xmm11,xmm11

		; ######################### R = x - K*2*pi ######################################

		MULPS xmm11,xmm4 	; xmm11 <- k*2
		MULPS xmm11,xmm3 	; xmm11 <- k*2*pi

		SUBPS xmm10,xmm11 	; xmm10 <- x - k*2*pi

		; ############################### X = R - pi ##################################

		SUBPS xmm10,xmm3 	; x <- r - pi

		; #################### Y = X - X³/6 + X⁵/120 - X⁷/5040 ####################

		; ############################### Y = X  ##################################

		MOVDQU xmm11,xmm10

		; ############################### x³/6 #####################################
		
		MOVDQU xmm14,xmm10
		MULPS xmm14,xmm10
		MULPS xmm14,xmm10
		DIVPS xmm14,xmm7


		; ############################ Y = x - x³/6 ################################

		SUBPS xmm11,xmm14

		; ############################### x⁵/120 #####################################
		
		MOVDQU xmm14,xmm10
		MULPS xmm14,xmm10
		MULPS xmm14,xmm14
		MULPS xmm14,xmm10
		DIVPS xmm14,xmm8


		; ############################ Y = x + x⁵/6 ################################

		ADDPS xmm11,xmm14

		; ############################### x⁷/5040 ##################################
		
		MOVDQU xmm14,xmm10
		MULPS xmm14,xmm10
		MULPS xmm14,xmm14
		MULPS xmm14,xmm10
		MULPS xmm14,xmm10
		MULPS xmm14,xmm10
		DIVPS xmm14,xmm9


		; ############################ Y = x + x⁵/6 - x⁷/5040 #########################

		SUBPS xmm11,xmm14

		; ######################## ESTADO DE LOS REGISTROS #############################

		; xmm11 <- sin_taylor(i.0/8.0), sin_taylor(i.0/8.0), sin_taylor(i.0/8.0), sin_taylor(i.0/8.0)
		; xmm12 <- sin_taylor((j+3).0/8.0), sin_taylor((j+2).0/8.0), sin_taylor((j+1).0/8.0), sin_taylor((j).0/8.0)
		; xmm13 <- sin_taylor((j+7).0/8.0), sin_taylor((j+6).0/8.0), sin_taylor((j+5).0/8.0), sin_taylor((j+4).0/8.0)


		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////////////// PROF DE I,J /////////////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////


		MULPS xmm11,xmm0 	; xmm11 <- x_sacale*sin_taylor(i.0/8.0), x_sacale*sin_taylor(i.0/8.0), x_sacale*sin_taylor(i.0/8.0), x_sacale*sin_taylor(i.0/8.0)

		MULPS xmm12,xmm1 	; xmm12 <- y_scale*sin_taylor((j+3).0/8.0), y_scale*sin_taylor((j+2).0/8.0), y_scale*sin_taylor((j+1).0/8.0), y_scale*sin_taylor((j).0/8.0)
		MULPS xmm13,xmm1 	; xmm13 <- y_scale*sin_taylor((j+7).0/8.0), y_scale*sin_taylor((j+6).0/8.0), y_scale*sin_taylor((j+5).0/8.0), y_scale*sin_taylor((j+4).0/8.0)

		ADDPS xmm12,xmm11 	; xmm12 <- x_sacale*sin_taylor(i.0/8.0) + y_scale*sin_taylor((j+3).0/8.0), ... ,x_sacale*sin_taylor(i.0/8.0) + y_scale*sin_taylor((j).0/8.0)
		ADDPS xmm13,xmm11 	; xmm13 <- x_sacale*sin_taylor(i.0/8.0) + y_scale*sin_taylor((j+7).0/8.0), ... ,x_sacale*sin_taylor(i.0/8.0) + y_scale*sin_taylor((j+4).0/8.0)

		DIVPS xmm12,xmm4 	; xmm12 <- Prof(i,j+3), ... ,Prof(i,j)
		DIVPS xmm13,xmm4 	; xmm13 <- Prof(i,j+7), ... ,Prof(i,j+4)

		; ////////////////////////////////////////////////////////////////////////////////
		; ////////////////////////////// I_dest(i,j) /////////////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		MULPS xmm12,xmm2 	; xmm12 <- Prof(i,j+3)*g_scale, ... ,Prof(i,j)*g_scale
		MULPS xmm13,xmm2 	; xmm13 <- Prof(i,j+7)*g_scale, ... ,Prof(i,j+4)*g_scale


		; ################## RECUPERO Y DESEMPAQUETO LOS DATOS DE LAIMAGEN ##############


		; traigo los datos de la memoria
		MOVQ xmm14,[rdi] 			; xmm10 <- [basura, ... ,basura,rdi+7, ... ,rdi+0]
		
		; desempaqueto de Byte a Word
		PXOR xmm11,xmm11 			; lo seteo en 0 para utilizarlo en el desempaquetamiento
		PUNPCKLBW xmm14,xmm11 		; xmm14 <- [00rdi+7, ... ,00rdi]	


		; desempaqueto de Word a Doubleword
		MOVDQU xmm15,xmm14
		PUNPCKLWD xmm14,xmm11 		; xmm14 <- [0000rdi+3, ... ,0000rdi]
		PUNPCKHWD xmm15,xmm11 		; xmm15 <- [0000rdi+7, ... ,0000rdi+4]

		; convierto a punto flotantes.
		; las imagenes estan en unsigned, pero como le agrego 0 tambien sirve como signed

		CVTDQ2PS xmm14,xmm14 		; xmm14 <- [(rdi+3).0, ... ,(rdi).0]
		CVTDQ2PS xmm15,xmm15 		; xmm15 <- [(rdi+7).0, ... ,(rdi+4).0]

		ADDPS xmm14,xmm12			; xmm14 <- Prof(i,j+3)*g_scale + (rdi+3).0, ... ,Prof(i,j)*g_scale + (rdi).0
		ADDPS xmm15,xmm13 			; xmm15 <- Prof(i,j+7)*g_scale + (rdi+7).0, ... ,Prof(i,j+4)*g_scale + (rdi+4).0

		; ########################## CONVIERTO A ENTEROS ##################################

		CVTTPS2DQ xmm14,xmm14 		; xmm14 <- [Prof(i,j+3)*g_scale + (rdi+3).0], ... ,[Prof(i,j)*g_scale + (rdi).0]
		CVTTPS2DQ xmm15,xmm15 		; xmm15 <- [Prof(i,j+7)*g_scale + (rdi+7).0], ... ,[Prof(i,j+4)*g_scale + (rdi+4).0]

		; ########################## EMPAQUETO SATURANDO ##################################
		
		; empaqueto de doubleWord a word
		PACKUSDW xmm14,xmm15

		; empaqueto de word a bytes
		PACKUSWB xmm14,xmm14

		; guardo los datos en el destino
		MOVQ [rsi],xmm14
		
	.configurarIteracion:

		; ////////////////////////////////////////////////////////////////////////////////
		; ///////////////// configuro la iteración del ciclo /////////////////////////////
		; ////////////////////////////////////////////////////////////////////////////////

		; ############# REGISTROS PARA EL LOOP ###########################################
		; rcx <- m - filas iteradas
		; rbx <- queda_ultimo_tramo o no
		; r10 <- [n/8] - ciclos iterados
		; r14 <- [n/8]
		; r15 <- resto [n/8]
		; r8  <- row_size - n

		; ###############################################################################


		DEC r10 	; decremento la cantidad de iteraciones que me faltan para terminar la fila actual

		; me fijo si ya llegue al final de la fila
		CMP r10,0
		JE .termine_iteraciones ; en el caso en que halla llegado al final debo ver si tengo que 
								; recorrer el proximo tramito o no

		; me fijo si mire el ultimo tramo
		CMP r10,-1
		JE .saltear_proxima_linea

		; si no termine las iteraciones entonces solo sumo 8 para pasar al proximo ciclo menos en la ultima vuelta donde no sumo nada
	.siguienteCiclo:
		ADD r13,8  		; r13 <- j = j+8 paso a los siguientes
		ADD rsi,8
		ADD rdi,8	
		JMP .finCiclo

		; si termine las iteraciones entonces me fijo si tengo que saltar directamente a la proxima fila o si queda un tramo menor a 16 por recorrer
	.termine_iteraciones:
		CMP rbx,No_Tiene_ultimo_tramo
		JE .saltear_proxima_linea 		; si no hay ultimo tramo salto directamente a la proxima fila a procesar 

		; si no salto es porque hay un ultimo tramo a recorrer
		ADD rdi,r15
		ADD rsi,r15
		ADD r13,r15
		JMP .finCiclo

	.saltear_proxima_linea:
		; pongo la memoria en la primera posición de la próxima linea
		ADD rdi,8
		ADD rsi,8	
		ADD rdi,r8 		; salteo el padding
		ADD rsi,r8		; salteo el padding

		; reseteo los datos de los contadores para una fila.		
		MOV r10,r14 		; le vuelvo a cargar la cantidad de iteraciones a realizar en una lina
		MOV r13,0 			; r13 <-j = 0

		; aumento el numero de la fila donde estamos
		INC r12 			; r12 <- i++

		; decremento la cantidad de filas que me faltan procesar
		DEC rcx 			; m - lineas procesadas


	.finCiclo:
		CMP rcx,0
		JNE .ciclo


.fin:
	POP r15
	POP r14
	POP r13
	POP r12
	POP rbx
	POP rbp
	RET