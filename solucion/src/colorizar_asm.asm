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

extern printf

section .data
    pixels:  DB 01, 05, 09, 02, 06, 10, 03, 07, 11, 04, 08, 12, 20,  40,  60,  80
    mask1:   DB 00, 03, 06, 09, 01, 04, 07, 10, 02, 05, 08, 11, 255, 255, 255, 255
    mask2:   DB 00, 04, 08, 01, 05, 09, 02, 06, 10, 03, 07, 11, 255, 255, 255, 255
    msg:     DB "%d ", 0
    newline: DB 10, 0

section .text

colorizar_asm:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8

    mov rbx, 0
loop_1:
    mov rdi, msg
    xor rax, rax
    mov al, [pixels + rbx]
    mov rsi, rax
    call printf
    inc rbx
    cmp rbx, 16
    jl loop_1

    mov rdi, newline
    call printf


    movdqu xmm0, [pixels]
    pshufb xmm0, [mask1]
    movdqu [pixels], xmm0


    mov rbx, 0
loop_2:
    mov rdi, msg
    xor rax, rax
    mov al, [pixels + rbx]
    mov rsi, rax
    call printf
    inc rbx
    cmp rbx, 16
    jl loop_2

    mov rdi, newline
    call printf


    movdqu xmm0, [pixels]
    pshufb xmm0, [mask2]
    movdqu [pixels], xmm0


    mov rbx, 0
loop_3:
    mov rdi, msg
    xor rax, rax
    mov al, [pixels + rbx]
    mov rsi, rax
    call printf
    inc rbx
    cmp rbx, 16
    jl loop_3

    mov rdi, newline
    call printf


    add rsp, 8
    pop rbx
    pop rbp
    ret