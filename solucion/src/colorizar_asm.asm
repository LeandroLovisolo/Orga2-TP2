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

section .text

colorizar_asm:
    push rbp
    mov rbp, rsp
    push rbx

    shl r8, 32                  ; Limpio parte alta de r8
    shr r8, 32
    shl r9, 32                  ; Limpio parte alta de r9
    shr r9, 32

    mov r11, 1                  ; r11 = y = 1

ciclo_y:

    mov r10, 3                  ; r10 = x = 3

ciclo_x:

    mov rax, r8                 ; eax = src_row_size
    mov rbx, r11                ; ebx = y
    mul ebx                     ; eax = src_row_size * y
    add rax, r10                ; eax = src_row_size * y + x

    movdqu xmm0, [rdi + rax]    ; xmmo0 = [src + (src_row_size * y + x)]

    mov rax, r9                 ; eax = dst_row_size
    mov rbx, r11                ; ebx = y
    mul ebx                     ; eax = dst_row_size * y
    add rax, r10                ; eax = dst_row_size * y + x

    movdqu [rsi + rax], xmm0    ; [dst + (dst_row_size * y + x)] = xmm0

    add r10, 3                  ; r10 = x = x + 3
    cmp r10, 1503
    jle ciclo_x


    add r11, 1                  ; r11 = y = y + 1
    cmp r11, 501
    jle ciclo_y

    pop rbx
    pop rbp
    ret