#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include <omp.h>

void img_inv(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	#pragma omp parallel num_threads(2)
	for (int i = 0; i < n; ++i)
		for (int j = 0; j < m; ++j)
			M[i * s_n + j * s_m] = 0xFF - M[i * s_n + j * s_m];
}
