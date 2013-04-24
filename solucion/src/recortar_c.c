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
            int a_src = src_row_size * y         + x;
            int a_dst = dst_row_size * (tam + y) + tam + x;

            int b_src = src_row_size * y         + tam + x;
            int b_dst = dst_row_size * (tam + y) + x;

            int c_src = src_row_size * (tam + y) + x;
            int c_dst = dst_row_size * y         + tam + x;
            
            int d_src = src_row_size * (tam + y) + tam + x;
            int d_dst = dst_row_size * y         + x;

            (*dst_matrix)[a_dst] = (*src_matrix)[a_src];
            (*dst_matrix)[b_dst] = (*src_matrix)[b_src];
            (*dst_matrix)[c_dst] = (*src_matrix)[c_src];
            (*dst_matrix)[d_dst] = (*src_matrix)[d_src];
        }
    }
}