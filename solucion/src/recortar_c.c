#include <stdio.h>

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
            int src = y * src_row_size + x;
            int dst = (tam + y) * dst_row_size + tam + x;
            (*dst_matrix)[dst] = (*src_matrix)[src];
        }
    }

    // Copio esquina B
    for(int y = 0; y < tam; y++) {
        for(int x = 0; x < tam; x++) {
            int src = y * src_row_size + tam + x;
            int dst = (tam + y) * dst_row_size + x;
            (*dst_matrix)[dst] = (*src_matrix)[src];
        }
    }

    // Copio esquina C
    for(int y = 0; y < tam; y++) {
        for(int x = 0; x < tam; x++) {
            int src = (tam + y) * src_row_size + x;
            int dst = y * dst_row_size + tam + x;
            (*dst_matrix)[dst] = (*src_matrix)[src];
        }
    }

    // Copio esquina D
    for(int y = 0; y < tam; y++) {
        for(int x = 0; x < tam; x++) {
            int src = (tam + y) * src_row_size + tam + x;
            int dst = y * dst_row_size + x;
            (*dst_matrix)[dst] = (*src_matrix)[src];
        }
    }    
}