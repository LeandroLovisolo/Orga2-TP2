#include <math.h>
void rotar_c (
    unsigned char *src,
    unsigned char *dst,
    int m,//Height
    int n, //Width
    int src_row_size,
    int dst_row_size
) {
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    double eqCx = n/2.0; //Longitud / 2
    double eqCy = m/2.0; //Altura / 2
    int cx = floor(eqCx); //Obtendo su parte entera
    int cy = floor(eqCy); //Obtengo su parte entera
    //Recorro la imágen de destino y le voy colocando el píxel correspondiente
    for(int y=0;y<m;y++) {
    	for(int x=0;x<n;x++) {
    		double u = cx + ((sqrt(2)/2) * (x - cx)) - ((sqrt(2)/2) * (y - cy)); //Ecuación u
    		double v = cy + ((sqrt(2)/2) * (x - cx)) +  ((sqrt(2)/2) * (y - cy)); //Ecuación v
  			unsigned int newU = floor(u);
  			unsigned int newV = floor(v);
    		if((0 <= u) && (u <= n) && (0 <= v) && (v <= m)) { //Es lo mismo usando newU y newV
    			dst_matrix[y][x] = src_matrix[newU][newV];
    		}
    		else {
    			dst_matrix[y][x] = 0;
    		}

    	}
    }
}