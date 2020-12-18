#include <casper.h>

#include <vector>

using namespace cac;

int main(int argc, char **argv) {
	Options opts; // metaprogram can add custom options
	opts.parseOrExit(argc, argv);

	TaskGraph tg("blur"); // must match target name in CMake script

	int img_width = 256, img_height = 200; // casper-256x200.bmp
	//int img_width = 1695, img_height = 1356; // casper.bmp
	//int img_width = 16950, img_height = 13560; // casper-tiled10.bmp
	//int img_width = 33900, img_height = 27120; // casper-tiled20.bmp

	const int BLUR_WIDTH = 16; // also set in Halide generator!

	Dat *img = &tg.createDat(img_height, img_width);

	Task& task_load = tg.createTask(CKernel("bmp_load"), {img});

	Task& task_inv = tg.createTask(CKernel("img_inv"), {img}, {&task_load});

	Dat* img_blurred = &tg.createDat(
			img_height - BLUR_WIDTH,
			img_width - BLUR_WIDTH);

	Task& task_blur = tg.createTask(HalideKernel("halide_blur"),
			{img, img_blurred}, {&task_inv});

	Task& task_save = tg.createTask(CKernel("bmp_save"), {img_blurred});

	return tryCompile(tg, opts);
}
