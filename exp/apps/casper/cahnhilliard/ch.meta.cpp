#include <casper.h>

#include <vector>

using namespace cac;

int main(int argc, char **argv) {
	Options opts; // metaprogram can add custom options
	opts.parseOrExit(argc, argv);

	TaskGraph tg{"ch"};

	tg.registerPyGenerator("kern", "generate");

	PyObj* state = &tg.createPyObj();

	Task& task_init = tg.createTask(FEMAKernel("kern", "init"), {state});
	Task& task_mass = tg.createTask(FEMAKernel("kern", "mass"),
			{state}, {&task_init});
	Task& task_hats = tg.createTask(FEMAKernel("kern", "hats"),
			{state}, {&task_init});
	Task& task_solve = tg.createTask(PyKernel("kern", "solve"), {state},
			{&task_mass, &task_hats});
	return tryCompile(tg, opts);
}
