ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

CASPER_UTILS_ROOT:=$(abspath ../../..)

NODES?=2
MAP_BY?=node
PATTERN?=.*
PATTERN_EXCLUDE?=^\$
LOG=
MAX_TIME_MIN?=30
ACCOUNT?=CASPER

all: dat/bench-prefix-n-2-map-by-node.log/job

dat/:
	mkdir -p "$@"

# TODO: NODES (and similar vars) should be part of the target name,
# and the recipe should extract it from there.

# Run osubench script from app-portage/osu-micro-benchmarks package,
# but using the host shell instead of the prefix shell (because to
# run mpirun, we must be oustide of the prefix).
#
# TODO: try to eliminate the PATH setting (it's for the mpirun wrappers)
dat/bench-prefix-n-$(NODES)-map-by-$(MAP_BY).log: | dat/
	$(EPREFIX)/usr/bin/osubench '$(PATTERN)' '$(PATTERN_EXCLUDE)' \
		mpirun -n "$(NODES)" --map-by "$(MAP_BY)" $(MPIRUN_ARGS)
.PHONY: run

DEBUG_Q=debug-cache-quad

%/job: | dat/
	rm -f $*.{cobaltlog,output,error}
	touch $*.{cobaltlog,output,error}
	qsub -O "$*" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ "$(NODES)" -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MAP_BY="$(MAP_BY)" \
		PATTERN="$(PATTERN)" PATTERN_EXCLUDE="$(PATTERN_EXCLUDE)" \
		MPIRUN_ARGS="$(MPIRUN_ARGS)" \
		$*
	tail -f $*.{cobaltlog,output,error}

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: job
