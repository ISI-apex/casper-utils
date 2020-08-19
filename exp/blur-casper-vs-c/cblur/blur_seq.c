#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

void img_blur(double *M_buf, double *M, int offset,
                int n, int m, int s_n, int s_m) {

        printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

        const int WIDTH = 17;
        const int BOUNDARY = WIDTH / 2;
        for (int i = BOUNDARY; i < n - BOUNDARY; ++i) {
                for (int j = BOUNDARY; j < m - BOUNDARY; ++j) {
                        double s = 0;
                        for (int v = -WIDTH / 2 + 1; v <= WIDTH / 2 - 1; ++v)
                                for (int w = -WIDTH/2 + 1; w <= WIDTH/2 - 1; ++w)
                                        s += M[(i + v) * s_n + (j + w) * s_m];

                        M[i * s_n + j * s_m] = s / (WIDTH*WIDTH);
                }
        }
}
