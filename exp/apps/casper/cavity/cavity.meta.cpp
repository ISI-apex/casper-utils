#include <casper.h>

#include <vector>

using namespace cac;

int main(int argc, char **argv) {
	Options opts; // metaprogram can add custom options
	opts.parseOrExit(argc, argv);

	TaskGraph tg("cavity");

	PyObj* sol = &tg.createPyObj();

	Task& task_fem = tg.createTask(PyKernel("kern", "solve_cavity"), {sol});
	Task& task_py = tg.createTask(PyKernel("kern", "save_sol"), {sol},
			{&task_fem});

	return tryCompile(tg, opts);
}
