ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

NODES?=2
MAP_BY?=node
PATTERN?=.*
LOG=bench-prefix-n-$(NODES)-map-by-$(MAP_BY).log
MAX_TIME_MIN?=180
ACCOUNT?=CASPER

all:
	echo "ERROR: no default target, valid targets are: job, run" 1>&2
	exit 1

# Run osubench script from app-portage/osu-micro-benchmarks package,
# but using the host shell instead of the prefix shell (because to
# run mpirun, we must be oustide of the prefix).
#
# TODO: try to eliminate the PATH setting (it's for the mpirun wrappers)
run:
	PATH=$(abspath ../../bin/theta):$${PATH} \
	     bash $(EPREFIX)/usr/bin/osubench "$(PATTERN)" \
		mpirun -n "$(NODES)" --map-by "$(MAP_BY)" $(MPIRUN_ARGS) command
.PHONY: run

DEBUG_Q=debug-cache-quad
LOGS:=$(LOG).{cobaltlog,output,error}

job:
	rm -f $(LOGS)
	touch $(LOGS)
	qsub -O "$(LOG)" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ "$(NODES)" -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MAP_BY="$(MAP_BY)" PATTERN="$(PATTERN)" \
		MPIRUN_ARGS="$(MPIRUN_ARGS)" \
		run
	tail -f $(LOGS)
.PHONY: job

jobi:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: jobi
