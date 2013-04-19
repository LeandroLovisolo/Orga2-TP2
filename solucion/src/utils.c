void copiar_bordes (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
) {
	for(int j = 0; j<n; j++) {
		// superior
		dst[0*row_size+j] = src[0*row_size+j];
		// inferior
		dst[(m-1)*row_size+j] = src[(m-1)*row_size+j];
	}

	for(int i = 0; i<m; i++) {
		// izquierdo
		dst[i*row_size+0] = src[i*row_size+0];
		// derecho
		dst[i*row_size+(n-1)] = src[i*row_size+(n-1)];
	}
}

void voltear_horizontal (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
) {
	unsigned char (*src_matrix)[row_size] = (unsigned char (*)[row_size]) src;
	unsigned char (*dst_matrix)[row_size] = (unsigned char (*)[row_size]) dst;

	for (int i = 0; i<m; i+=1) {
		for (int j = 0; j<n; j+=1) {
			dst_matrix[i][n-j-1] = src_matrix[i][j];
		}
	}
}