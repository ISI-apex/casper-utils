#ifndef BMP_H
#define BMP_H

void bmp_load(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m);
void bmp_save(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m);

#endif /* BMP_H */
