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
    and rax, 0x00000000FFFFFFFF ; Limpio la parte alta de rax
    sub rax, r10                ; rax = tam - x
    cmp eax, 16
    jl menos_de_16_columnas

    ; Guardo en eax el desplazamiento en src
    mov rax, r11    ; eax = y
    mov rbx, r8     ; ebx = src_row_size
    mul ebx         ; eax = y * src_row_size
    add rax, r10    ; eax = y * src_row_size + x
    and rax, 0x00000000FFFFFFFF ; Limpio la parte alta de rax

    movdqu xmm0, [r12 + rax]
    movdqu [r13 + rax], xmm0

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