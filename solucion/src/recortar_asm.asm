; void recortar_asm (
;   unsigned char *src,
;   unsigned char *dst,
;   int m,
;   int n,
;   int src_row_size,
;   int dst_row_size,
;   int tam
; );

; Parámetros:
;   rdi = src
;   rsi = dst
;   rdx = m
;   rcx = n
;   r8 = src_row_size
;   r9 = dst_row_size
;   rbp + 16 = tam

extern recortar_c

global recortar_asm

extern printf
section .data
    msg: db "(%d, %d)", 10, 0

section .text

recortar_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Guardo los parámetros
    mov r12, rdi    ; r12 = src
    mov r13, rsi    ; r13 = dst
    mov r14, rdx    ; r14 = m
    mov r15, rcx    ; r15 = n

    ; push qword [rbp + 16]
    ; call recortar_c
    ; add rsp, 8

    xor r11, r11    ; r11 = y = 0

ciclo_y:
    xor r10, r10    ; r10 = x = 0

ciclo_x:
    mov rax, [rbp + 16]         ; rax = tam
    sub rax, r10                ; rax = tam - x
    cmp eax, 16
    jl menos_de_16_columnas

    ;;;;;;;;;;;;;;;
    ;; Esquina A ;;
    ;;;;;;;;;;;;;;;

    ; Copio
    mov rax, r11                ; eax = y
    mov rbx, r8                 ; ebx = src_row_size
    mul ebx                     ; eax = src_row_size * y
    add rax, r10                ; eax = src_row_size * y + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu xmm0, [r12 + rax]    ; xmm0 = [src + (src_row_size * y + x)]

    ; Pego
    mov rax, [rbp + 16]         ; eax = tam
    add rax, r11                ; eax = tam + y
    mov rbx, r9                 ; ebx = dst_row_size
    mul ebx                     ; eax = dst_row_size * (tam + y)
    add rax, [rbp + 16]         ; eax = dst_row_size * (tam + y) + tam
    add rax, r10                ; eax = dst_row_size * (tam + y) + tam + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu [r13 + rax], xmm0    ; [dst + (dst_row_size * (tam + y) + tam + x)] = xmm0

    push r8
    push r9
    push r10
    push r11
    sub rsp, 8
    mov rdi, msg
    mov rsi, r10
    mov rdx, r11
    call printf
    add rsp, 8
    pop r11
    pop r10
    pop r9
    pop r8

    add r10, 16
    jmp ciclo_x

menos_de_16_columnas:
    inc r11
    mov rax, [rbp + 16]         ; rax = tam
    mov rbx, r11
    cmp eax, ebx
    jne ciclo_y

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret