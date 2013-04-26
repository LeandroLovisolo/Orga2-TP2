void halftone_c (

	unsigned char *src,
	unsigned char *dst,
	int m, 	// ancho de la imagen en pixeles
	int n, 	// alto de la imagen en pixeles
	int src_row_size, // tamaño real de la matriz
	int dst_row_size // tamaño real de la matriz
) {
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;


	int t;

	for(int i = 0; i < m; i+=2){
		for (int j = 0; j < n; j+=2)
		{
			t = 0;
			t += src_matrix[i][j];
			t += src_matrix[i][j+1];
			t += src_matrix[i+1][j];
			t += src_matrix[i+1][j+1];

			if(t < 205){

				dst_matrix[i][j] 		= 0;
				dst_matrix[i][j+1] 		= 0;
				dst_matrix[i+1][j] 		= 0;
				dst_matrix[i+1][j+1]	= 0;

			}else if(t < 410){

				dst_matrix[i][j] 		= 255;				
				dst_matrix[i][j+1] 		= 0;
				dst_matrix[i+1][j] 		= 0;
				dst_matrix[i+1][j+1]	= 0;				

			}else if(t < 615){

				dst_matrix[i][j] 		= 255;				
				dst_matrix[i][j+1] 		= 0;
				dst_matrix[i+1][j] 		= 0;
				dst_matrix[i+1][j+1]	= 255;
				
			}else if(t < 820){

				dst_matrix[i][j] 		= 255;				
				dst_matrix[i][j+1] 		= 0;
				dst_matrix[i+1][j] 		= 255;
				dst_matrix[i+1][j+1]	= 255;
				
			}else{

				dst_matrix[i][j] 		= 255;				
				dst_matrix[i][j+1] 		= 255;
				dst_matrix[i+1][j] 		= 255;
				dst_matrix[i+1][j+1]	= 255;
			}
		}
	}
}


