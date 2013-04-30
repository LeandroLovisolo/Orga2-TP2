#include <math.h>
#include <stdio.h>
void rotar_c (
    unsigned char *src,
    unsigned char *dst,
    int m,//Height
    int n, //Width
    int src_row_size,
    int dst_row_size
) {
    printf("Image height: %d, image width: %d \n", m, n);
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    double eqCx = n/2.0; //Longitud / 2
    double eqCy = m/2.0; //Altura / 2
    int cx = floor(eqCx); //Obtendo su parte entera
    int cy = floor(eqCy); //Obtengo su parte entera
    double square = (sqrt(2)/2);
    //Recorro la imágen de destino y le voy colocando el píxel correspondiente
    for(int y=0;y<m;y++) {
    	for(int x=0;x<n;x++) {
    		float u = cx + (square * (x - cx)) - (square * (y - cy)); //Ecuación u
    		//float v = cy + (square * (x - cx)) +  (square * (y - cy)); //Ecuación v
            //float u1 = cx + (square * (x - cx));
            //float u2 = -(square * (y - cy));
            float v1 = cy + (square * (x - cx));
            float v2 = (square * (y - cy));
  			int newU = u;
            int newV = v1 + v2;
            if((x == 149 && y == 0) || (x == 148 && y == 1)) {
               printf("Square: %f \n",square);
               printf("cx = %d, cy = %d , (x - cx) = %d , (y - cy) = %d \n", cx, cy, (x-cx), (y-cy));
            }
    		if((0 <= newU) && (newU <= n) && (0 <= newV) && (newV <= m)) { //Es lo mismo usando newU y newV
                if((x == 149 && y == 0) || (x == 148 && y == 1)) {
                    printf("Le queda %d \n", src_matrix[newV][newU]);
                }
    			dst_matrix[y][x] = src_matrix[newV][newU];
    		}
    		else {
                if((x == 149 && y == 0) || (x == 148 && y == 1)) {
                    printf("Le queda 0 \n");
                }
    			dst_matrix[y][x] = 0;
    		}

    	}
    }
}