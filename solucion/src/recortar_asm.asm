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

global recortar_asm

section .text

recortar_asm:

    push rbp
    mov rbp, rsp
    push rbx
    push r12

    ; Guardo parámetro m

    mov r12d, edx               ; r12d = m

    ; Comienzo a iterar sobre las filas

    xor r11d, r11d              ; r11d = y = 0

ciclo_y:
    
    ; Comienzo a iterar sobre las columnas de la fila actual

    xor r10d, r10d              ; r10d = x = 0

ciclo_x:

    ; Termino el ciclo x sólo si terminamos de recorrer la fila actual

    mov eax, [rbp + 16]         ; eax = tam
    sub eax, r10d               ; eax = tam - x
    jz fin_ciclo_x              ; Salto al fin del ciclo si tam - x = 0

    ; Compruebo si quedan más de 16 pixels por recorrer

    cmp eax, 16
    jge mas_de_16_columnas      ; Salto si tam - x >= 16

    ; Quedan menos de 16, retrocedo hasta que queden exactamente 16

    mov ebx, 16                 ; ebx = 16
    sub ebx, eax                ; ebx = 16 - (tam - x)
    sub r10d, ebx               ; r10d = x = x - [16 - (tam - x)]

mas_de_16_columnas:

    ;;;;;;;;;;;;;;;
    ;; Esquina A ;;
    ;;;;;;;;;;;;;;;

    ; Copio

    mov eax, r11d               ; eax = y
    mov ebx, r8d                ; ebx = src_row_size
    mul ebx                     ; eax = src_row_size * y
    add eax, r10d               ; eax = src_row_size * y + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu xmm0, [rdi + rax]    ; xmm0 = [src + (src_row_size * y + x)]

    ; Pego

    mov eax, [rbp + 16]         ; eax = tam
    add eax, r11d               ; eax = tam + y
    mov ebx, r9d                ; ebx = dst_row_size
    mul ebx                     ; eax = dst_row_size * (tam + y)
    add eax, [rbp + 16]         ; eax = dst_row_size * (tam + y) + tam
    add eax, r10d               ; eax = dst_row_size * (tam + y) + tam + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu [rsi + rax], xmm0    ; [dst + (dst_row_size * (tam + y) + tam + x)] = xmm0

    ;;;;;;;;;;;;;;;
    ;; Esquina B ;;
    ;;;;;;;;;;;;;;;

    ; Copio

    mov eax, r11d               ; eax = y
    mov ebx, r8d                ; ebx = src_row_size
    mul ebx                     ; eax = src_row_size * y
    add eax, ecx                ; eax = src_row_size * y + n
    sub eax, [rbp + 16]         ; eax = src_row_size * y + n - tam
    add eax, r10d               ; eax = src_row_size * y + n - tam + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu xmm0, [rdi + rax]    ; xmm0 = [src + (src_row_size * y + n - tam + x)]

    ; Pego

    mov eax, [rbp + 16]         ; eax = tam
    add eax, r11d               ; eax = tam + y
    mov ebx, r9d                ; ebx = dst_row_size
    mul ebx                     ; eax = dst_row_size * (tam + y)
    add eax, r10d               ; eax = dst_row_size * (tam + y) + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu [rsi + rax], xmm0    ; [dst + (dst_row_size * (tam + y) + x)] = xmm0

    ;;;;;;;;;;;;;;;
    ;; Esquina C ;;
    ;;;;;;;;;;;;;;;

    ; Copio

    mov eax, r12d               ; eax = m
    sub eax, [rbp + 16]         ; eax = m - tam
    add eax, r11d               ; eax = m - tam + y
    mov ebx, r8d                ; ebx = src_row_size
    mul ebx                     ; eax = src_row_size * (m - tam + y)
    add eax, r10d               ; eax = src_row_size * (m - tam + y) + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu xmm0, [rdi + rax]    ; xmm0 = [src + (src_row_size * (m - tam + y) + x)]

    ; Pego

    mov eax, r11d               ; eax = y
    mov ebx, r9d                ; ebx = dst_row_size
    mul ebx                     ; eax = dst_row_size * y
    add eax, [rbp + 16]         ; eax = dst_row_size * y + tam
    add eax, r10d               ; eax = dst_row_size * y + tam + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu [rsi + rax], xmm0    ; [dst + (dst_row_size * (tam + y) + tam + x)] = xmm0

    ;;;;;;;;;;;;;;;
    ;; Esquina D ;;
    ;;;;;;;;;;;;;;;

    ; Copio

    mov eax, r12d               ; eax = m
    sub eax, [rbp + 16]         ; eax = m - tam
    add eax, r11d               ; eax = m - tam + y
    mov ebx, r8d                ; ebx = src_row_size
    mul ebx                     ; eax = src_row_size * (m - tam + y)
    add eax, ecx                ; eax = src_row_size * (m - tam + y) + n
    sub eax, [rbp + 16]         ; eax = src_row_size * (m - tam + y) + n - tam
    add eax, r10d               ; eax = src_row_size * (m - tam + y) + n - tam + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32    
    movdqu xmm0, [rdi + rax]    ; xmm0 = [src + (src_row_size * (m - tam + y) + n - tam + x)]

    ; Pego

    mov eax, r11d               ; eax = y
    mov ebx, r9d                ; ebx = dst_row_size
    mul ebx                     ; eax = dst_row_size * y
    add eax, r10d               ; eax = dst_row_size * y + x
    shl rax, 32                 ; Limpio parte alta de rax
    shr rax, 32
    movdqu [rsi + rax], xmm0    ; [dst + (dst_row_size * y + x)] = xmm0

    add r10d, 16                ; r10d = x = x + 16
    jmp ciclo_x

fin_ciclo_x:

    inc r11d                    ; r11d = y = y + 1
    mov eax, [rbp + 16]         ; eax = tam
    mov ebx, r11d
    cmp eax, ebx
    jne ciclo_y

    pop r12
    pop rbx
    pop rbp
    ret