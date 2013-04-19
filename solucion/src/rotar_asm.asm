; void rotar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int m,
; 	int n,
; 	int src_row_size,
; 	int dst_row_size
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = m
; 	rcx = n
; 	r8 = src_row_size
; 	r9 = dst_row_size

extern rotar_c

global rotar_asm

section .text

rotar_asm:
	;; TODO: Implementar

	sub rsp, 8

	call rotar_c

	add rsp, 8

	ret
