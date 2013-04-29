unsigned char min(unsigned char a, float b) {
    return a < b ? a : b;
}

unsigned char max(unsigned char a, unsigned char b) {
    return a > b ? a : b;
}

unsigned char max_9(unsigned char xs[9]) {
    unsigned char x = xs[0];
    for(int i = 1; i < 9; i++) {
        x = max(x, xs[i]);
    }
    return x;
}

enum channel { R, G, B };

float phi(unsigned char *img, int row_size, int i, int j, float alpha, enum channel c) {
    unsigned char (*img_matrix)[row_size] = (unsigned char (*)[row_size]) img;

    unsigned char pixels_r[9];
    unsigned char pixels_g[9];
    unsigned char pixels_b[9];

    int k = 0;
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            pixels_r[k] = img_matrix[j + y][3 * (i + x) + 2];
            pixels_g[k] = img_matrix[j + y][3 * (i + x) + 1];
            pixels_b[k] = img_matrix[j + y][3 * (i + x)];
            k++;
        }
    }

    unsigned char max_r = max_9(pixels_r);
    unsigned char max_g = max_9(pixels_g);
    unsigned char max_b = max_9(pixels_b);

    switch(c) {
        case R:  return max_r >= max_g && max_r >= max_b ? (1 + alpha) : (1 - alpha);
        case G:  return max_r <  max_g && max_g >= max_b ? (1 + alpha) : (1 - alpha);
        default: return max_r <  max_b && max_g <  max_b ? (1 + alpha) : (1 - alpha);
    }
}

void colorizar_c (
    unsigned char *src,
    unsigned char *dst,
    int m,
    int n,
    int src_row_size,
    int dst_row_size,
    float alpha
) {
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    for(int y = 1; y < m - 1; y++) {
        for(int x = 1; x < n - 1; x++) {
            float phi_r = phi(src, src_row_size, x, y, alpha, R);
            float phi_g = phi(src, src_row_size, x, y, alpha, G);
            float phi_b = phi(src, src_row_size, x, y, alpha, B);
            
            unsigned char src_b = src_matrix[y][3 * x];
            unsigned char src_g = src_matrix[y][3 * x + 1];
            unsigned char src_r = src_matrix[y][3 * x + 2];

            dst_matrix[y][3 * x]     = min(255, phi_b * src_b);
            dst_matrix[y][3 * x + 1] = min(255, phi_g * src_g);
            dst_matrix[y][3 * x + 2] = min(255, phi_r * src_r);
        }
    }
}