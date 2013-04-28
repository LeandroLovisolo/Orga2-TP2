; void colorizar_asm (
;   unsigned char *src,
;   unsigned char *dst,
;   int m,
;   int n,
;   int src_row_size,
;   int dst_row_size,
;   float alpha
; );

; Parámetros:
;   rdi = src
;   rsi = dst
;   rdx = m
;   rcx = n
;   r8 = src_row_size
;   r9 = dst_row_size
;   xmm0 = alpha


global colorizar_asm

section .data

    align 16
    mask_rrr_ggg_bbb: db 0,   3,   6,   255, 1,   4,   7,   255, 2,   5,   8,   255, 255, 255, 255, 255
    mask_r_g_b:       db 0,   255, 255, 255, 4,   255, 255, 255, 8,   255, 255, 255, 255, 255, 255, 255
    mask_pxl2chn:     db 0,   255, 255, 255, 1,   255, 255, 255, 2,   255, 255, 255, 255, 255, 255, 255
    mask_chn2pxl:     db 0,   4,   8,   255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
    tupla_255:        dd 255.0, 255.0, 255.0, 0
    uno:              dd 1.0

section .text

colorizar_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    ; Guardo parámetros
    mov r12, rdx                ; r12 = m
    mov r13, rcx                ; r13 = n

    shl r8, 32                  ; Limpio parte alta de r8
    shr r8, 32
    shl r9, 32                  ; Limpio parte alta de r9
    shr r9, 32

    mov r11, 1                  ; r11 = y = 1

ciclo_y:

    mov r10, 3                  ; r10 = x = 3

ciclo_x:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Computar Phi: Inicio ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Obtengo los tres vecinos superiores

    mov rax, r8                 ; eax = src_row_size
    mov rbx, r11                ; ebx = y
    dec ebx                     ; ebx = y - 1
    mul ebx                     ; eax = src_row_size * (y - 1)
    add rax, r10                ; eax = src_row_size * (y - 1) + x
    sub rax, 3                  ; eax = src_row_size * (y - 1) + x - 3
    movdqu xmm1, [rdi + rax]    ; xmm1 = [src + (src_row_size * (y - 1) + x - 3)]

    ; Obtengo pixel actual y vecinos a izquierda y derecha

    mov rax, r8                 ; eax = src_row_size
    mov rbx, r11                ; ebx = y
    mul ebx                     ; eax = src_row_size * y
    add rax, r10                ; eax = src_row_size * y + x
    sub rax, 3                  ; eax = src_row_size * y + x - 3
    movdqu xmm2, [rdi + rax]    ; xmm2 = [src + (src_row_size * y + x - 3)]

    ; Obtengo los tres vecinos inferiores

    mov rax, r8                 ; eax = src_row_size
    mov rbx, r11                ; ebx = y
    inc ebx                     ; ebx = y + 1
    mul ebx                     ; eax = src_row_size * (y + 1)
    add rax, r10                ; eax = src_row_size * (y + 1) + x
    sub rax, 3                  ; eax = src_row_size * (y + 1) + x - 3
    movdqu xmm3, [rdi + rax]    ; xmm3 = [src + (src_row_size * (y + 1) + x - 3)]    

    ; Reordeno los bytes de la siguiente manera: 
    ; ____ ___R GBRG BRGB => 0000 0RRR 0GGG 0BBB

    pshufb xmm1, [mask_rrr_ggg_bbb]
    pshufb xmm2, [mask_rrr_ggg_bbb]
    pshufb xmm3, [mask_rrr_ggg_bbb]

    ; Guardo en xmm1 los máximos columna por columna

    pmaxub xmm1, xmm2
    pmaxub xmm1, xmm3

    ; Extraigo cada tripla RGB en un registro xmm distinto:
    ; 0000 0RRR 0GGG 0BBB => 0000 000R 000G 000B (xmm1, xmm2, xmm3)

    movdqu xmm2, xmm1           ; xmm2 = 0000 0RRR 0GGG 0BBB
    pshufb xmm2, [mask_r_g_b]   ; xmm2 = 0000 000R 000G 000B

    psrld xmm1, 8               ; xmm1 = 0000 00RR 00GG 00BB
    movdqu xmm3, xmm1           ; xmm3 = 0000 00RR 00GG 00BB
    pshufb xmm3, [mask_r_g_b]   ; xmm3 = 0000 000R 000G 000B

    psrld xmm1, 8               ; xmm1 = 0000 000R 000G 000B

    ; Guardo en xmm1 los máximos columna por columna

    pmaxub xmm1, xmm2
    pmaxub xmm1, xmm3           ; xmm1 = 0000 maxR maxG maxB

    ; Extraigo maxB, maxG y maxR

    xor rcx, rcx                ; rcx = 0
    movd ecx, xmm1              ; ecx = maxB

    xor rbx, rbx                ; rbx = 0
    pshufd xmm2, xmm1, 1        ; xmm2 = ____ ____ ____ maxG
    movd ebx, xmm2              ; ebx = maxG

    xor rax, rax                ; rax = 0
    pshufd xmm2, xmm1, 2        ; xmm2 = ____ ____ ____ maxR
    movd eax, xmm2              ; eax = maxR

    ;;; Computo PhiR ;;;

    cmp eax, ebx
    jl phi_r_falso              ; maxR >= maxG
    cmp eax, ecx                
    jl phi_r_falso              ; maxR >= maxB

    movss xmm1, [uno]           ; xmm1 = 0000 0000 0000 1.0
    addss xmm1, xmm0            ; xmm1 = 0000 0000 0000 (1.0 + alpha) = PhiR
    jmp phi_g

phi_r_falso:

    movss xmm1, [uno]           ; xmm1 = 0000 0000 0000 1.0
    subss xmm1, xmm0            ; xmm1 = 0000 0000 0000 (1.0 - alpha) = PhiR

    ;;; Computo PhiG ;;;

phi_g:

    cmp eax, ebx
    jge phi_g_falso             ; maxR < maxG
    cmp ebx, ecx                
    jl phi_g_falso              ; maxG >= maxB

    movss xmm2, [uno]           ; xmm2 = 0000 0000 0000 1.0
    addss xmm2, xmm0            ; xmm2 = 0000 0000 0000 (1.0 + alpha) = PhiG
    jmp phi_b

phi_g_falso:

    movss xmm2, [uno]           ; xmm2 = 0000 0000 0000 1.0
    subss xmm2, xmm0            ; xmm2 = 0000 0000 0000 (1.0 - alpha) = PhiG

    ;;; Computo PhiB ;;;

phi_b:

    cmp eax, ecx
    jge phi_b_falso             ; maxR < maxB
    cmp ebx, ecx                
    jge phi_b_falso             ; maxG < maxB

    movss xmm3, [uno]           ; xmm3 = 0000 0000 0000 1.0
    addss xmm3, xmm0            ; xmm3 = 0000 0000 0000 (1.0 + alpha) = PhiB
    jmp tupla_phi

phi_b_falso:

    movss xmm3, [uno]           ; xmm3 = 0000 0000 0000 1.0
    subss xmm3, xmm0            ; xmm3 = 0000 0000 0000 (1.0 - alpha) = PhiB

    ; Guardo la tupla Phi = (PhiR, PhiG, PhiB) en xmm1 de la siguiente forma:
    ; xmm1 = 0000 PhiR PhiG PhiB

tupla_phi:

    pshufd xmm1, xmm1, 0xC6     ; xmm1 = 0000 PhiR 0000 0000
    pshufd xmm2, xmm2, 0xE1     ; xmm2 = 0000 0000 PhiG 0000
    addps xmm1, xmm2            ; xmm1 = 0000 PhiR PhiG 0000
    addps xmm1, xmm3            ; xmm1 = 0000 PhiR PhiG PhiB

    ;;;;;;;;;;;;;;;;;;;;;;;
    ;; Computar Phi: Fin ;;
    ;;;;;;;;;;;;;;;;;;;;;;;

    ; Leo pixel actual

    mov rax, r8                 ; eax = src_row_size
    mov rbx, r11                ; ebx = y
    mul ebx                     ; eax = src_row_size * y
    add rax, r10                ; eax = src_row_size * y + x
    movdqu xmm2, [rdi + rax]    ; xmm2 = [src + (src_row_size * y + x)]

    ; Reordeno los canales y los convierto a floats

    pshufb xmm2, [mask_pxl2chn] ; xmm2 = 0000 000R 000G 000B
    cvtdq2ps xmm2, xmm2         ; xmm2 = 0000 Rsrc Gsrc Bsrc

    ; Obtengo la tupla (PhiR * Rsrc, PhiG * Gsrc, PhiB * Bsrc)

    mulps xmm2, xmm1            ; xmm2 = 0000 (PhiR * Rsrc) (PhiG * Gsrc) (PhiB * Bsrc)
    
    ; Obtengo la tupla (Rdst, Gdst, Bdst) con los valores para el pixel destino

    movdqu xmm1, [tupla_255]    ; xmm1 = 0000 255.0        255.0        255.0
    minps xmm1, xmm2            ; xmm1 = 0000 Rdst         Gdst         Bdst
    cvtps2dq xmm1, xmm1         ; xmm1 = 0000 (0 0 0 Rdst) (0 0 0 Gdst) (0 0 0 Bdst)

    ; Armo el pixel destino

    pshufb xmm1, [mask_chn2pxl] ; xmm2 = 0000 0000 0000 (0 Rdst Gdst Bdst)
    movd ecx, xmm1

    ; Escribo pixel destino

    mov rax, r9                 ; eax = dst_row_size
    mov rbx, r11                ; ebx = y
    mul ebx                     ; eax = dst_row_size * y
    add rax, r10                ; eax = dst_row_size * y + x
    add [rsi + rax], ecx        ; [dst + (dst_row_size * y + x)] += ecx

    ; Iteración ciclo x

    add r10, 3                  ; r10 = x = x + 3
    cmp r10, 1503
    jle ciclo_x

    ; Iteración ciclo y

    add r11, 1                  ; r11 = y = y + 1
    cmp r11, 501
    jle ciclo_y

    pop r13
    pop r12
    pop rbx
    pop rbp
    ret