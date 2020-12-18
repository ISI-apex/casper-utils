#include <casper.h>

#include <vector>

using namespace cac;

int main(int argc, char **argv) {
	Options opts; // metaprogram can add custom options
	opts.parseOrExit(argc, argv);

	TaskGraph tg("matrix");
	tg.setDatPrint(true);

	std::vector<double> matValsA {
		1.000000e+00, -2.000000e+00,
		3.000000e+00, 4.000000e+00,
		5.000000e+00, -6.000000e+00,
	};
	Dat *matA = &tg.createDat(3, 2, matValsA);

	std::vector<double> matValsB {
		1.000000e+00, -2.000000e+00,
		3.000000e+00, 4.000000e+00,
		8.000000e+00, 3.000000e+00,
	};
	Dat* matB = &tg.createDat(3, 2, matValsB);

	Task& task_inv = tg.createTask(CKernel("mat_invert"), {matA});
	Task& task_abs = tg.createTask(CKernel("mat_abs"), {matB});

	Task& task_add = tg.createTask(CKernel("mat_add"), {matA, matB},
			{&task_inv, &task_abs});

	Dat *matC = &tg.createDat(3, 2);
	Scalar *offset = &tg.createIntScalar(/* width */ 8, 2);
	Task& task_bright = tg.createTask(HalideKernel("halide_bright"),
			{offset, matA, matC}, {&task_add});

	return tryCompile(tg, opts);
}
