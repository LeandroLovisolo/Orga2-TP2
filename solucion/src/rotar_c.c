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
    int count = 0;
    for(int y = 0; y < m; y++) {
        for(int x = 0; x < n; x++) {
            float cx = floor(n/2.0);
            float cy = floor(m/2.0);
            float u = cx + sqrt(2)/2.0 * (x - cx) - sqrt(2)/2.0 * (y - cy);
            float v = cy + sqrt(2)/2.0 * (x - cx) + sqrt(2)/2.0 * (y - cy);
            if(0 <= (int) u && u < n && 0 <= (int) v && v < m) {
                dst_matrix[(int) y][(int) x] = src_matrix[(int) v][(int) u];
            } else {
                dst_matrix[(int) y][(int) x] = 0;
            }
        }
    }
}