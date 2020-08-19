#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "bmp.h"
#include "blur.h"
#include "inv.h"

int main(int argc, char **argv)
{
#if 0
	int img_width = 1695, img_height = 1356; // casper.bmp
#else
#if 1
	int img_width = 16950, img_height = 13560; // casper-tiled10.bmp
#else
	int img_width = 33950, img_height = 27120; // casper-tiled20.bmp
#endif
#endif
	double *img = (double *)malloc(img_width * img_height * sizeof(double));

	bmp_load(img, img, 0, img_height, img_width, img_width, 1);
	img_inv(img, img, 0, img_height, img_width, img_width, 1);
	img_blur(img, img, 0, img_height, img_width, img_width, 1);
	bmp_save(img, img, 0, img_height, img_width, img_width, 1);

	free(img);
	return 0;
}

