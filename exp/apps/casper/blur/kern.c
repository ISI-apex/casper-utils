#include <assert.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

void img_inv(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {

	printf("%d, %d %d, %d %d\n", offset, n, m, s_n, s_m);

	for (int i = 0; i < n; ++i)
		for (int j = 0; j < m; ++j)
			M[i * s_n + j * s_m] = 0xFF - M[i * s_n + j * s_m];
}

static uint32_t read_int(FILE *f, int offset) {
	uint32_t r;
	if (fseek(f, offset, SEEK_SET) != 0) {
		perror("failed to fseek to size header field");
		exit(1);
	}
	int rc = fread(&r, sizeof(uint32_t), 1, f);
	if (rc != 1) {
		perror("failed to read pixel array offset header field");
		exit(1);
	}
	return r;
}

static const char *INPUT_IMG_PATH = "casper.bmp";
static const char *OUTPUT_IMG_PATH = "casper_blurred.bmp";
static const int IMG_PIX_ROW_PADDING = 0; /* pixel width aligned to 4 */
static const int BLUR_BOUNDARY = 0; /* function of Halide pipeline */
static const int BLUR_WIDTH = 16; /* also set in Halide generator and
				     in the metaprogram! */

void bmp_load(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {
	FILE *fin = fopen(INPUT_IMG_PATH, "r");
	if (!fin) {
		perror("failed to open image file");
		exit(1);
	}
	uint32_t size = read_int(fin, 2);
	uint32_t pix_off = read_int(fin, 10);
	printf("size %x pix off %x m %d n %d\n", size, pix_off, m, n);

	if (fseek(fin, pix_off, SEEK_SET) != 0) {
		perror("failed to fseek to pixel array");
		exit(1);
	}

	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < m; ++j) {
			uint8_t pix;
			if (fread(&pix, sizeof(uint8_t), 1, fin) != 1) {
				fprintf(stderr, "eof %d\n", feof(fin));
				perror("failed to read pixel");
				exit(1);
			}
			M[i * s_n + j * s_m] = pix;
		}
		if (fseek(fin, IMG_PIX_ROW_PADDING, SEEK_CUR) != 0) {
			perror("failed to fseek to next row in pixel array");
			exit(1);
		}
	}
	fclose(fin);
}

static void copy_file(FILE *fin, FILE *fout) {
	static uint8_t buffer[4096];
	size_t count;
	while ((count = fread(buffer, 1, sizeof(buffer), fin)) > 0) {
		if (fwrite(buffer, 1, count, fout) != count) {
			perror("failed to copy while writing to output image");
			exit(1);
		}
	}
	if (ferror(fin)) {
		perror("failed to copy while reading from input image");
		exit(1);
	}
}

void bmp_save(double *M_buf, double *M, int offset,
		int n, int m, int s_n, int s_m) {
	// copy the input image to grab headers etc, then overwrite pixel array
	FILE *fout = fopen(OUTPUT_IMG_PATH, "w");
	if (!fout) {
		perror("failed to open output image file");
		exit(1);
	}
	FILE *fin = fopen(INPUT_IMG_PATH, "r");
	if (!fin) {
		perror("failed to open input image file");
		exit(1);
	}
	copy_file(fin, fout);
	uint32_t pix_off = read_int(fin, 10);
	fclose(fin);

	if (fseek(fout, pix_off, SEEK_SET) != 0) {
		perror("failed to fseek to pixel array");
		exit(1);
	}

	int ii = 0, jj = 0;
	for (int i = 0; i < n + BLUR_WIDTH; ++i) {
		for (int j = 0; j < m + BLUR_WIDTH; ++j) {
			if (BLUR_WIDTH/2 <= i && i < n + BLUR_WIDTH/2 &&
			    BLUR_WIDTH/2 <= j && j < m + BLUR_WIDTH/2) {
				uint8_t pix = M[ii * s_n + jj * s_m];
				if (fwrite(&pix, sizeof(uint8_t), 1, fout) != 1) {
					perror("failed write pixel data to output image");
					exit(1);
				}
				jj++;
				if (jj == m) {
					jj = 0;
					ii++;
				}
			} else {
				if (fseek(fout, 1, SEEK_CUR) != 0) {
					perror("failed to fseek to skip boundary pixel");
					exit(1);
				}
			}
		}
		if (fseek(fout, IMG_PIX_ROW_PADDING, SEEK_CUR) != 0) {
			perror("failed to fseek to next row in pixel array");
			exit(1);
		}
	}

	fclose(fout);
}
