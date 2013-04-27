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
      
    for(int y = 0; y < tam; y++) {
        for(int x = 0; x < tam; x++) {
            dst_matrix[tam + y][tam + x] = src_matrix[y          ][x          ]; // A
            dst_matrix[tam + y][x      ] = src_matrix[y          ][n - tam + x]; // B
            dst_matrix[y      ][tam + x] = src_matrix[m - tam + y][x          ]; // C
            dst_matrix[y      ][x      ] = src_matrix[m - tam + y][n - tam + x]; // D
        }
    }
}