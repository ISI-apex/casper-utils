#include <assert.h>
#include <stdio.h>

void mat_abs(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < m; ++j) {
			double v = M[i * s_n + j * s_m];
			if (v < 0)
				M[i * s_n + j * s_m] = -v;
		}
	}
}

void mat_double(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < m; ++j) {
				M[i * s_n + j * s_m] *= 2;
		}
	}
}

void mat_tripple(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < m; ++j) {
				M[i * s_n + j * s_m] *= 3;
		}
	}
}

void mat_invert(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < m; ++j) {
				M[i * s_n + j * s_m] *= -1;
		}
	}
}

void mat_add(
		double *A_buf, double *A, int A_offset,
		int A_n, int A_m, int A_s_n, int A_s_m,
		double *B_buf, double *B, int B_offset,
		int B_n, int B_m, int B_s_n, int B_s_m) {

	printf("%d, %d %d, %d %d\n", A_offset, A_n, A_m, A_s_n, A_s_m);
	printf("%d, %d %d, %d %d\n", B_offset, B_n, B_m, B_s_n, B_s_m);

	assert(A_n == B_n && A_m == B_m);

	for (int i = 0; i < A_n; ++i) {
		for (int j = 0; j < A_m; ++j) {
				A[i * A_s_n + j * A_s_m] += B[i * B_s_n + j * B_s_m];
		}
	}
}
