; void rotar_asm (
;   unsigned char *src,
;   unsigned char *dst,
;   int m,
;   int n,
;   int src_row_size,
;   int dst_row_size
; );

; Parámetros:
;   rdi = src
;   rsi = dst
;   rdx = m
;   rcx = n
;   r8 = src_row_size
;   r9 = dst_row_size

extern rotar_c

global rotar_asm

section .rodata
square: DD 0x3F3504F7

section .text

rotar_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov r14, rcx
    dec r14
    mov r8,rdx
    dec r8
    ;########################################################
    ;Calculo cx ; Queda en xmm1 = cx
    ;########################################################
    mov rax, 2d;
    movq xmm3, rax ;Pongo el número 2
    shufps xmm3, xmm3, 0d ;Lleno de 2's double words a xmm1
    cvtdq2pd xmm3, xmm3 ;Convierto los 2's en 2's doubles
    movq xmm1, rcx ;Pongo en xmm1 la longitud
    shufps xmm1, xmm1, 0d ;Lleno de longitudes double word a xmm1
    cvtdq2pd xmm1, xmm1 ;Convierto las longitudes en 2 longitudes doubles
    divpd xmm1, xmm3 ;Divido por 2
    cvttpd2dq xmm1, xmm1 ;Trunco
    cvtdq2pd xmm1, xmm1 ;Vuelvo a convertir a doubles
    ;########################################################
    ;Calculo cy ; Queda en xmm2 = cy
    ;########################################################
    movq xmm2, rdx ;Pongo en xmm2 la altura
    shufps xmm2, xmm2, 0d ;Lleno de alturas double word
    cvtdq2pd xmm2, xmm2 ;Convierto las alturas en 2 longitudes doubles
    divpd xmm2, xmm3 ;Divido por 2
    cvttpd2dq xmm2, xmm2 ;Trunco
    cvtdq2pd xmm2, xmm2 ;Vuelvo a convertir a doubles
    ;########################################################
    ;Calculo sqrt(2)/2
    ;########################################################
    movdqu xmm4, xmm3 ;Hago una copia de los 2 doubles packed con 2's
    sqrtpd xmm3, xmm3 ;Le calculo la raíz cuadrada a 2 usando doubles
    divpd xmm3, xmm4 ;Divido por 2
    ;################################################################################################################
    ;La mejor manera de paralelizar es, agarrando los siguientes 4 pixeles en el destino, calcular de esta manera
    ;la posición de que pixel le correspone (para ĺos 4 píxeles en simultaneo), es necesario usar doubles por la precisión:
    ;Dividir u en u1 y u2: u1 = cx + (sqrt(2)/2)*(x-cx)   y u2 = -(sqrt(2)/2)*(y-cy)
    ;Dividir v en v1 y v2: v1 = cy + (sqrt(2)/2)*(x-cx)   y v2 = +(sqrt(2)/2)*(y-cy)
    ;Una vez calculadas las pocisiones, mover a un buffer y repetir hasta llenarlo, una vez lleno, copiarlo al destino
    ;################################################################################################################
    ;################################################################################################################
    ;Antes de entrar al ciclo:
    ;xmm1 -> Contine 2 double con cx packed
    ;xmm2 -> Contine 2 double con cy packed
    ;xmm3 -> Contiene 2 double con sqrt(2)/2 packed
    ;################################################################################################################
    xor r11, r11 ;Va a contener la posición x
    xor r15, r15 ;Va a contener la posición y
    .cicloPrincipal:
    mov r13, 4d ;Settea los 4 iteraciones que se van a realizar para conseguir los 16 bytes a poner
    pxor xmm7, xmm7 ;Acumulador de los 16 bytes a poner
    .ciclo:
        ;############################################################################
        ;Meto las posiciones de los 4 x's en xmm4 y los 4 y's en xmm6 siguientes
        ;############################################################################
        mov rcx, 4d
        .cicloSetpixels:
            pslldq xmm4, 4 ;Shifteo 4 bytes para ir acomodando los 4 números en dwords
            movd xmm11, r11d ;Pongo en xmm11 1 de las 4 posiciones de x
            por xmm4, xmm11 ;Hago un por entre xmm4 y xmm11 para poder dejar en la parte baja de xmm4 el número
            inc r11 ;Incremento x
            pslldq xmm6, 4 ;4 bytes para ir acomodando los 4 números en dwords
            movd xmm11, r15d ;Pongo en xmm6 1 de las 4 posiciones de y
            por xmm6, xmm11 ;Hago un por entre xmm6 y xmm11 para poder dejar en la parte baja de xmm6 el número
            cmp r11, r9 ;Veo si x recorrió toda la linea, si lo hizo, cambio de linea y pongo a x en 0
            jne .vuelvoAciclar
            inc r15 ;Incremento y
            mov r11, 0d ;Pongo x = 0
            .vuelvoAciclar:
            loop .cicloSetpixels

        ;##########################
        ;Parte baja y alta de x
        ;#########################
        movdqu xmm8, xmm4 ;Hago una copia
        cvtdq2pd xmm4, xmm4 ;Tengo doubles bajos
        psrldq xmm8, 8 ;Shifteo 8 bytes a la der para conseguir los doubles altos
        cvtdq2pd xmm8, xmm8 ;Tengo doubles altos
        ;##########################
        ;Parte baja y alta de y
        ;##########################
        movdqu xmm9, xmm6 ;Hago una copia
        cvtdq2pd xmm6, xmm6 ;Tengo doubles bajos
        psrldq xmm9, 8 ;Shifteo 8 bytes a la der para conseguir los doubles altos
        cvtdq2pd xmm9, xmm9 ;Tengo doubles altos
        ;##################################################
        ;Calculo xmm4 = u1 xmm7 = u1
        ;##################################################
        subpd xmm4, xmm1 ;hago (x-cx) parte baja
        mulpd xmm4, xmm3 ;Multiplico por (sqrt(2)/2) parte baja
        subpd xmm8, xmm1 ;hago (x-cx) parte alta
        mulpd xmm8, xmm3 ;Multiplico por (sqrt(2)/2) parte alta
        ;Como (sqrt(2)/2)*(x-cx) se usa en v1 y u1 me lo guardo
        movdqu xmm5, xmm4 ;Hago la copia de la parte baja de u1
        movdqu xmm10, xmm8 ;Hago la copia de la parte alta de u1
        addpd xmm4, xmm1 ;termino teniendo cx + (sqrt(2)/2)*(x-cx) parte baja
        addpd xmm8, xmm1 ;termino teniendo cx + (sqrt(2)/2)*(x-cx) parte alta
        ;##################################################
        ;Calculo baja xmm5 = v1 alta xmm10 = v1
        ;##################################################
        addpd xmm5, xmm2 ;v1 = cy + (sqrt(2)/2)*(x-cx) parte baja
        addpd xmm10, xmm2 ;v1 = cy + (sqrt(2)/2)*(x-cx) parte alta
        ;##################################################
        ;Calculo xmm6 = u2 y v2 (Son las mismas, una la resto a u1 y otra la sumo a v1)
        ;##################################################
        subpd xmm6, xmm2  ;Parte baja hago (y-cy) 
        subpd xmm9, xmm2  ;Parte alta hago (y-cy) 
        mulpd xmm6, xmm3  ;Parte baja Multiplico por (sqrt(2)/2)
        mulpd xmm9, xmm3 ;Parte alta Multiplico por (sqrt(2)/2)
        ;##################################################
        ;Saco xmm5 = v = v1 + v2 y xmm4 = u = u1 - u2
        ;##################################################
        subpd xmm4, xmm6 ;Le resto a u1 parte baja (sqrt(2)/2)*(y-cy)
        subpd xmm8, xmm9 ;Le resto a u1 parte alta (sqrt(2)/2)*(y-cy)
        addpd xmm5, xmm6 ;Le sumo a v1 parte baja (sqrt(2)/2)*(y-cy)
        addpd xmm10, xmm9 ;Le sumo a v1 parte alta (sqrt(2)/2)*(y-cy)
        ;############################################################################################################
        ;Trunco y convierto a int
        ;Para que funcione hay que hacer todas las cuentas en double, pasarlas a float
        ;y después pasarlas a entero
        ;############################################################################################################
        ;Trabajo con X's
        cvtpd2ps xmm4, xmm4 ;Convierto la parte baja a float
        cvtpd2ps xmm8, xmm8 ;Convierto la parte alta a float
        cvttps2dq xmm4, xmm4 ;Convierto la parte baja a int 
        cvttps2dq xmm8, xmm8 ;Convierto la parte alta a int 
        pslldq xmm8, 8 ;Lo muevo 8 bytes a la izquierda para colocar los enteros de xmm4
        pxor xmm8, xmm4
        ;Trabajo con Y's
        cvtpd2ps xmm5, xmm5 ;Convierto la parte baja a float
        cvtpd2ps xmm10, xmm10 ;Convierto la parte alta a float
        cvttps2dq xmm5, xmm5 ;Convierto la parte baja a int
        cvttps2dq xmm10, xmm10 ;Convierto la parte alta a int
        pslldq xmm10, 8 ;Lo muevo 8 bytes a la izquierda para colocar los enteros de xmm10
        pxor xmm10, xmm5
        ;##################################################
        ;Proceso los 4 bytes, byte por byte
        ;##################################################
        mov rcx, 4d ;Voy a ciclar 4 veces para poder conseguir 16 bytes
        xor rbp, rbp ;Limpio rbp que va a almacenar las quadwords con los bytes antes de mandarlas
        .cicloProceso:
            movd r10d, xmm8 ;Pongo u en r10
            movd r12d, xmm10 ;Pongo v en r12
            psrldq xmm8, 4;shifteo 4 bytes para después poder usar los otros
            psrldq xmm10, 4;shifteo 4 bytes para después poder usar los otros
            cmp r10d, r14d ;Veo si u < n
            jg .ponerCero ;Cambio jge por jg ya que decrementé n
            cmp r10d, 0d ;Veo si u <= 0
            jl .ponerCero
            cmp r12d, r8d ;Veo si v < m
            jg .ponerCero ;Cambio jge por jg ya que decrementé m
            cmp r12d, 0d ;Veo si v <= 0
            jl .ponerCero
            xor rax, rax ;Limpio rax
            ;###########################################
            ;Calculo posición de donde proviene el byte
            ;###########################################
            mov eax, r12d
            mul r9d ;Me muevo en filas
            add rax, r10 ;Me muevo en columnas
            add rax, rdi ;Sumo la dirección de la matríz src
            shl rbp, 8 ;Voy acumulando los valores que deberían ser los píxeles
            add bpl, [rax] ;Agrego el byte al registro acumulador rbp
            cmp rcx, 0d ;Me fijo si ya hice 4 ciclos
            dec rcx
            je .finCicloProceso ;Si ya completé los 4 ciclos, salgo
            jmp .cicloProceso ;Si no, a ciclar otra vez
            .ponerCero: ;En caso de que haya que poner el valor en 0
            shl rbp, 8 ;Corro rbp 1 byte (8 bits) a la izquierda para simular un 0
            loop .cicloProceso ;A ciclar
        .finCicloProceso:
        pslldq xmm7, 4 ;Usando nuestro acumulador principal, lo corro 4 bytes para poner los nuevos
        movq xmm11,rbp ;Copio a xmm11, rbp
        por xmm7, xmm11 ;Agrego a xmm7 los 4 bytes de rbp
        dec r13 ;Decremento el contador de ciclos para llenar 16 bytes
        cmp r13, 0d ;Veo si llegué al 0, si lo hice llené los 16 bytes
        jg .ciclo ;Si no lo hice, vuelvo a ciclar hasta llenar los 16 bytes
        shufps xmm7, xmm7, 00011011b ;Los roto (necesario ya que con tantos almacenamientos quedan mal)
        movdqu [rsi], xmm7 ;Si completo los 16 bytes a mandar, los mando y me fijo donde estoy
        add rsi, 16d ;Me muevo 16 bytes
        cmp r15, r8 ;Veo si estoy en la última fila ;CMP CON DOUBLES
        jne .cicloPrincipal
        cmp r11, r14 ;Si estoy en la última columna, salgo
        je .fin
        ;Si no, me fijo si puedo agarrar los siguientes 16 bytes
        mov rax, 16d
        add rax, r11
        cmp rax, r14
        jl .cicloPrincipal ;Si es menor, todo bien
        ;Si no es menor, tengo que ir para atrás para que me queden 16 bytes justos
        sub rax, r14 ;Consigo cuanto necesito para llegar a 16 justos
        sub r11, rax ;Se lo resto a mi numero x
        sub rsi, rax ;Se lo resto al puntero de la imagen fuente
        jmp .cicloPrincipal

    .fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
