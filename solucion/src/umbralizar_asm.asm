; void umbralizar_c (
;   unsigned char *src,
;   unsigned char *dst,
;   int m,
;   int n,
;   int row_size,
;   unsigned char min,
;   unsigned char max,
;   unsigned char q
; );

; Parámetros:
;   rdi = src
;   rsi = dst
;   rdx = m
;   rcx = n
;   r8 = row_size
;   r9 = min
;   rbp + 16 = max
;   rbp + 24 = q

extern umbralizar_c

global umbralizar_asm

section .rodata
pckSuffleMask: DQ 0x0100010001000100, 0x0100010001000100
grValue: DQ 0xffffffffffffffff, 0xffffffffffffffff

section .text

umbralizar_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov r12, [rbp + 16] ;Guardo el máximo
    mov r13, [rbp + 24] ;Guardo Q
    mov rbp, rsp
    and r13, 00000000000000FFh
    and r12, 00000000000000FFh ;Pongo todo en 0's excepto el máximo que es un byte
    ;###################################################################################################################
    ;Preparación del máximo para realizar comparaciones más tarde
    ;###################################################################################################################
    movq xmm5, r12
    ;pxor xmm6, xmm6 ;Pongo la máscara de packed shuffle en xmm6
    movdqu xmm6, [pckSuffleMask]
    pshufb xmm5, xmm6 ;Me queda en xmm5 el máximo repetido en words
    ;Armo registro para poner bytes en FF si es > max
    movdqu xmm9, [grValue]
    ;###################################################################################################################
    ;Preparación del mínimo para hacer comparaciones más tarde
    ;###################################################################################################################
    pxor xmm11, xmm11 ;Creo una máscara para packed shuffle byte para poner en todos los bytes el minimo
    movq xmm12, r9 ;Pongo el minimo en xmm12
    pshufb xmm12, xmm11 ;Me pone el mínimo en todos los bytes
    and r9, 000000000000000FFh
    movq xmm11, r9
    pshufb xmm11, xmm6 ;Me queda el mínimo repetido en words para realizar luego la comparación
    ;###################################################################################################################
    ;xmm12 ->  Contiene en todos los bytes el mínimo
    ;xmm11 ->  Contiene el mínimo repetido en words
    ;xmm9  ->  Contiene en todos los bytes 255
    ;xmm5  ->  Contiene el máximo repetido en words
    ;###################################################################################################################
    mov rax, r8
    mul rdx
    mov rcx, rax
    .ciclo:
        pxor xmm8, xmm8 ;Mi acumulador
    	movdqu xmm1, [rdi] ;Muevo 16 bytes o pixeles a xmm1
        ;Voy a desempaquetar los bytes para poder convertirlos a signed y realizar comparaciones de >
        movdqu xmm2, xmm1 ;Hago una copia en xmm2
        movdqu xmm15, xmm1 ;Hago una copia en xmm13
        ;Dejo en xmm2 una máscara para ver cuales son iguales al min, esto se hace ya que no hago
        ; p < min y necesito saber cuales son >= min
        ;Por lo tanto, cuando haga < voy a tener que filtrar los =
        pcmpeqb xmm15, xmm12 
        ;###################################################################################################################
        ;Desempaqueto los bytes que tengo a words para poder usar la comparación greater than
        ;###################################################################################################################
        punpcklbw xmm1, xmm8 ;Pongo la parte baja en xmm1
        punpckhbw xmm2, xmm8 ;Pongo la parte alta en xmm2
        ;###################################################################################################################
        ;Creación de máscara y aplicación de la misma para los números mayores al máximo
        ;###################################################################################################################
        movdqu xmm3, xmm1 ;Realizo la copia para hacer la comparación
        movdqu xmm4, xmm2
        pcmpgtw xmm3, xmm5 ;Veo si mis pixeles convertidos a word son mayores que el máximo
        pcmpgtw xmm4, xmm5 ;Esto me deja una máscara de words
        packsswb xmm3, xmm4 ;Hago el empaquetamiento otra vez y me queda una máscara para hacer la suma al acum 
        ;packuswb xmm3, xmm4 ; VER POR QUE FUNCIONA SIGNED Y NO UNSIGNED COMO DEBERÍA
        movdqu xmm10, xmm9 ;Hago una copia de la double quadword de 255's, 255 es el valor que le corresponde a los números > max
        pand xmm10, xmm3 ;Aplico la máscara de máximos a xmm10 para que me quede cuales pixeles van a ser 255 y poder sumar
        paddusb xmm8, xmm10 ;Pongo en el acumulador los bits que le corresponden tener 255
        ;###################################################################################################################
        ;Creación de máscara para los pixeles que están entre min <= p <= max
        ;Para esto busco los mayores al min, una vez obtenida la máscara, hago xor con los mayores al max y or con los iguales al min
        ;###################################################################################################################
        movdqu xmm13, xmm1 ;Realizo la copia para aplicarle la máscara
        movdqu xmm14, xmm2
        pcmpgtw xmm13, xmm11 ;Me fijo si son > min y me deja la máscara
        pcmpgtw xmm14, xmm11
        packsswb xmm13, xmm14 ;Hago el empaquetamiento otra vez y me queda una máscara por bytes SIGNED
        pxor xmm13, xmm3 ;Le borro a la máscara los que son mayores que el máximo
        por xmm13, xmm15 ;Le pongo a la máscara los que son iguales que el mínimo
        ;###################################################################################################################
        ;Ya tengo la máscara para los que estan entre min <= p <= max, falta calcular para cada pixel su valor
        ;###################################################################################################################
        ;Para utilizar floats necesito desempaquetar aún más las words de los registros desempaquetados previamente
        ;en parte baja y alta también. Para cada una: convertirlos en floats, convertir también Q en float, realizar la división,
        ;convertirlos a enteros truncandolo para hacer la función floor y luego volver a convertirlos a float para realizar
        ;la multiplicacion por Q (Es la mejor manera)
        ;###################################################################################################################
        ;############################################################
        ;Trabajo con las words resultantes del desempaquetamiento low
        ;############################################################
        pxor xmm7, xmm7
        movdqu xmm14, xmm1 ;Hago una copia de las words más bajas
        movdqu xmm15, xmm1 ;Hago una copia de las words mas altas
        ;Convierto words correspondientes a la parte baja a double words para usar operaciones de pto flotante
        punpcklwd xmm14, xmm7 ;Desempaqueto aun mas todo y lo convierto a double word
        punpckhwd xmm15, xmm7
        ;Los convierto a sigle presition floats
        cvtdq2ps xmm14, xmm14 ;Convierte las words en single Single-Precision floats
        cvtdq2ps xmm15, xmm15
        ;#############################
        ;Setteo en xmm3 el valor de q  PODRIA METERSE EN XMM6 AL PRINCIPIO!
        ;#############################
        movq xmm3, r13 ;Muevo Q a xmm3
        shufps xmm3, xmm3, 0d ;Lleno de Q's words a xmm3
        cvtdq2ps xmm3, xmm3 ;Convierto q a float para dividir
        ;#############################
        ;Hago las divisiones por q
        ;#############################
        divps xmm14, xmm3 ;Divide Packed Single-Precision Floating-Point Values
        divps xmm15, xmm3
        ;#############################
        ;Trunco a enteros para hacer la función float
        ;#############################
        cvttps2dq xmm14, xmm14 ;CVTTPS2DQ—Convert with Truncation Packed Single-Precision FP Values to Packed Dword Integers
        cvttps2dq xmm15, xmm15
        ;#############################
        ;Una vez truncados, los convierto otra vez a float para hacer la multiplicacion
        ;#############################
        cvtdq2ps xmm14, xmm14
        cvtdq2ps xmm15, xmm15
        mulps xmm14, xmm3
        mulps xmm15, xmm3
        ;#############################
        ;Convierto a enteros y empaqueto
        ;#############################
        cvttps2dq xmm14, xmm14 ;Convierto todo a int otra vez para empaquetarlo
        cvttps2dq xmm15, xmm15
        ;Acá hay que empaquetar sin signo! aunque así funciona bien 
        packssdw xmm14, xmm15 ;empaqueto todo otra vez y lo dejo en xmm14 SIGNED!
        ;############################################################
        ;Trabajo con las words resultantes del desempaquetamiento high
        ;############################################################
        movdqu xmm15, xmm2 ;Hago una copia
        movdqu xmm10, xmm2
        punpcklwd xmm15, xmm7 ;Desempaqueto aun mas todo y lo convierto a double word
        punpcklwd xmm10, xmm7 ;Desempaqueto aun mas todo y lo convierto a double word

        ;Los convierto a sigle presition floats
        cvtdq2ps xmm15, xmm15 ;CVTDQ2PS—Convert Packed Dword Integers to Packed Single-Precision FP Values
        cvtdq2ps xmm10, xmm10
        ;#############################
        ;Hago las divisiones por q
        ;#############################
        divps xmm15, xmm3 ;Divide Packed Single-Precision Floating-Point Values
        divps xmm10, xmm3
        ;#############################
        ;Trunco a enteros para hacer la función float
        ;#############################
        cvttps2dq xmm15, xmm15 ;Truco para hacer la funcion floor
        cvttps2dq xmm10, xmm10
        ;#############################
        ;Una vez truncados, los convierto otra vez a float para hacer la multiplicacion
        ;#############################
        cvtdq2ps xmm14, xmm14
        cvtdq2ps xmm15, xmm15 
        mulps xmm15, xmm3
        mulps xmm10, xmm3
        ;#############################
        ;Convierto a enteros y empaqueto
        ;#############################
        cvttps2dq xmm15, xmm15 ;Convierto todo a int otra vez para empaquetarlo
        cvttps2dq xmm10, xmm10
        packssdw xmm15, xmm10 ;empaqueto todo otra vez y lo dejo en xmm15 SIGNED
        ;###################################################################################################################
        ;Empaquetado y armado final de los bytes a colocar
        ;###################################################################################################################
        packsswb xmm14, xmm15 ;Vuelvo a empaquetar dejando todo en bytes en xmm14 SIGENED
        pand xmm14, xmm13 ;Le aplico la máscara para el caso anteriormente creada
        paddusb xmm8, xmm14 ;Lo sumo al acumulador
        ;###################################################################################################################
        ;No hace ya falta calcular los < min, ya cubrimos los mayores al max ylos que estan min <= p <= max ,
        ;los únicos que sobran van a ser < mín no es necesario ponerlos en 0 ya que ya lo estan
        ;###################################################################################################################
        movdqu [rsi], xmm8 ;lo pongo en memoria
        add rdi, 16d ;Adelanto otros 16 bytes la imagen src
        add rsi, 16d ;Adelanto otros 16 bytes la imagen dst
        sub rcx, 16d ;RCX tiene la cantidad de píxeles que existe, le resto los 16 que ya ví
        cmp rcx, 16d
        jg .ciclo
        je .fin
        jl .muevoParaAtras
    .muevoParaAtras:
    xor rax, rax
    mov rax, 16d
    sub rax, rcx
    sub rdi, rax
    jmp .ciclo
    .fin:
    pop r13
    pop r12
    pop rbp

    ret