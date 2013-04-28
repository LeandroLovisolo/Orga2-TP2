#include <math.h>

// terminar esto, no se en que punto quieren que la evalue
float sin_taylor (float x) {

	const float pi 	= 3.14159265359;
	float k 		= (int)(x/(2*pi));
	float r 		= x - k*2*pi;
	x 				= r - pi;
	float y = x - ((x*x*x)/6) ;
}

void waves_c (
    unsigned char *src,
    unsigned char *dst,
    int m,
    int n,
    int row_size,
    float x_scale,
    float y_scale,
    float g_scale
) {
    unsigned char (*src_matrix)[row_size] = (unsigned char (*)[row_size]) src;
    unsigned char (*dst_matrix)[row_size] = (unsigned char (*)[row_size]) dst;

	double prof;

	for (int i = 0; i < m; ++i){
		for (int j = 0; j < n; ++j){
			
			prof = ( x_scale*sin_taylor(i/8) + y_scale*sin_taylor(j/8) )/2;
			double newValue = prof*g_scale + src_matrix[i][j];

			if(newValue > 255) newValue = 255;
			else if(newValue < 0) newValue = 0;

			unsigned int value = floor(newValue);
			dst_matrix[i][j] = value;
		}
	}
}
