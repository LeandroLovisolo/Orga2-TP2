#include <stdio.h>

typedef unsigned char uchar;

void recortar_c (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int src_row_size,
	int dst_row_size,
	int tam
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    
    // Copio esquina A
    for(int y = 0; y < tam; y++) {
        for(int x = 0; x < tam; x++) {
            uchar* dst = (uchar*) dst_matrix + (tam + y) * dst_row_size + tam + x;
            uchar* src = (uchar*) src_matrix + (y * src_row_size) + x;
            *dst = *src;
        }
    }
}