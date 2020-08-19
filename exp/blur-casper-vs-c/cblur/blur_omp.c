#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#define OMP
#define NTHREADS 8
static const int TILE_SIZE = 8192;

#ifdef OMP
#include <omp.h>
#endif

static inline double win_avg(double *M, int i, int j, int s_n, int s_m)
{
	const int WIDTH = 17;
	double s = 0;
	for (int v = -WIDTH / 2 + 1; v <= WIDTH / 2 - 1; ++v)
		for (int w = -WIDTH/2 + 1; w <= WIDTH/2 - 1; ++w)
			s += M[(i + v) * s_n + (j + w) * s_m];
	return s / (WIDTH * WIDTH);	
}

void img_blur(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	const int BOUNDARY = 1;

	// boundary at granularity of tile
#ifdef OMP
#ifdef NTHREADS
	#pragma omp parallel num_threads(NTHREADS)
#else
	#pragma omp parallel
#endif
#endif
	for (int ii = 1; ii < n/TILE_SIZE - 1; ++ii)
		for (int jj = 1; jj < m/TILE_SIZE - 1; ++jj)

			for (int i = ii * TILE_SIZE; i < (ii * TILE_SIZE) + TILE_SIZE;
					++i)
				for (int j = jj * TILE_SIZE; j < (jj * TILE_SIZE) + TILE_SIZE;
					   	++j)
					M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);

	// handle the outer box (width of the box is 1 tile)
	int ii,jj;

	// top boundary
	ii = 0;
#ifdef OMP
#ifdef NTHREADS
	#pragma omp parallel num_threads(NTHREADS)
#else
	#pragma omp parallel
#endif
#endif
	for (int jj = 1; jj < m/TILE_SIZE - 1; ++jj) {
		for (int i = BOUNDARY; i < TILE_SIZE; ++i)
			for (int j = jj * TILE_SIZE;
					j < (jj * TILE_SIZE) + TILE_SIZE; ++j)
				M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	}
	// bottom boundary
	ii = n/TILE_SIZE - 1;
#ifdef OMP
#ifdef NTHREADS
	#pragma omp parallel num_threads(NTHREADS)
#else
	#pragma omp parallel
#endif
#endif
	for (int jj = 1; jj < m/TILE_SIZE - 1; ++jj) {
		for (int i = ii * TILE_SIZE;
				i < ii * TILE_SIZE + TILE_SIZE - BOUNDARY; ++i)
			for (int j = jj * TILE_SIZE;
					j < (jj * TILE_SIZE) + TILE_SIZE; ++j)
				M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	}

	// left boundary
	jj = 0;
#ifdef OMP
#ifdef NTHREADS
	#pragma omp parallel num_threads(NTHREADS)
#else
	#pragma omp parallel
#endif
#endif
	for (int ii = 1; ii < n/TILE_SIZE - 1; ++ii) {
		for (int i = 0; i < TILE_SIZE; ++i)
			for (int j = BOUNDARY; j < TILE_SIZE; ++j)
				M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	}
	// right boundary
	jj = n/TILE_SIZE - 1;
#ifdef OMP
#ifdef NTHREADS
	#pragma omp parallel num_threads(NTHREADS)
#else
	#pragma omp parallel
#endif
#endif
	for (int ii = 1; ii < n/TILE_SIZE - 1; ++ii) {
		for (int i = ii * TILE_SIZE; i < ii * TILE_SIZE + TILE_SIZE - BOUNDARY; ++i)
			for (int j = jj * TILE_SIZE;
					j < jj * TILE_SIZE + TILE_SIZE - BOUNDARY; ++j)
				M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	}

	// top-left corner
	for (int i = BOUNDARY; i < TILE_SIZE; ++i)
		for (int j = BOUNDARY; j < TILE_SIZE; ++j)
			M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	// top-right corner
	for (int i = BOUNDARY; i < TILE_SIZE; ++i)
		for (int j = 0; j < TILE_SIZE - BOUNDARY; ++j)
			M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	// bottom-left corner
	ii = n/TILE_SIZE - 1;
	jj = m/TILE_SIZE - 1;
	for (int i = ii * TILE_SIZE;
		   i < ii * TILE_SIZE + TILE_SIZE - BOUNDARY; ++i)
		for (int j = jj * TILE_SIZE + BOUNDARY;
				j < jj * TILE_SIZE + TILE_SIZE; ++j)
			M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
	// bottom-right corner
	for (int i = ii * TILE_SIZE;
		   i < ii * TILE_SIZE + TILE_SIZE - BOUNDARY; ++i)
		for (int j = jj * TILE_SIZE;
				j < jj * TILE_SIZE + TILE_SIZE - BOUNDARY; ++j)
			M[i * s_n + j * s_m] = win_avg(M, i, j, s_n, s_m);
}
