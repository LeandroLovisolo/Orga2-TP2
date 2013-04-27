#include <math.h>
void umbralizar_c (
	unsigned char *src,
	unsigned char *dst,
	int m, //Hight
	int n, //Width
	int row_size,
	unsigned char min,
	unsigned char max,
	unsigned char q
) {
	unsigned char (*src_matrix)[row_size] = (unsigned char (*)[row_size]) src;
	unsigned char (*dst_matrix)[row_size] = (unsigned char (*)[row_size]) dst;
	float ecuacion = 0.0;
	for(int y=0;y<m;y++) {
		for(int x=0;x<n;x++) {
			if(src_matrix[y][x] < min) { //Es valor de la escala de grises menor que el mínimo?
				dst_matrix[y][x] = 0;
			}
			else if(src_matrix[y][x] > max) { //Es valor de la escala de grises mayor que el máximo?
				dst_matrix[y][x] = 255;
			}
			else {
				ecuacion = (src_matrix[y][x] / q);
				dst_matrix[y][x] = floor(ecuacion) * q; //Asigno el nuevo valor
			}
		}
		
	}
}
