; void umbralizar_c (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int m,
; 	int n,
; 	int row_size,
; 	unsigned char min,
; 	unsigned char max,
; 	unsigned char q
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = m
; 	rcx = n
; 	r8 = row_size
; 	r9 = min
; 	rbp + 16 = max
; 	rbp + 24 = q

extern umbralizar_c

global umbralizar_asm

section .text

umbralizar_asm:
	;; TODO: Implementar

	push rbp
	mov rbp, rsp

	push qword [rbp + 24]
	push qword [rbp + 16]
	call umbralizar_c
	add rsp, 16

	pop rbp

	ret
