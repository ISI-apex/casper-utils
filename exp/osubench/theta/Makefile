ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

CASPER_UTILS_ROOT:=$(abspath ../../..)

NODES?=2
MAP_BY?=node-NOLOCAL

# By default, include all except one-sided benchmarks (observed hang from
# within prefix, although need to retest), and exclude multi-threaded
# bechmarks because they either take very long or even hang in an infinite
# loop/deadlock (unclear). startup (osu_init) causes SIGILL.
PATTERN?=pt2pt|collective
PATTERN_EXCLUDE?=_mt$$

MAX_TIME_MIN?=30
ACCOUNT?=CASPER
DATA_DIR?=dat
BLOCK?=

# UCX and OFI don't work; builtin uGNI and builtin TCP do work
DATS=\
     $(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-default.log
# TODO: multiple concurrent targets not supported, b/c need to block qsub
#     $(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp.log

all: $(patsubst %,%/job,$(DATS))

dat: $(DATS)

# if NODES <= 8 (debug queue), then allow only one job at a time
ifneq ($(filter 1 2 3 4 5 6 7 8,$(NODES)),)
.NOTPARALLEL:
endif

$(DATA_DIR)/:
	mkdir -p "$@"

ifneq ($(VERBOSE),)
MPIRUN_TP_ARGS+=\
	--mca pml_base_verbose 100 \
	--mca odls_base_verbose 100 \
	--mca opal_verbose 100 \
	--mca opal_base_verbose 100 \
	--mca ras_base_verbose 100 \
	--mca plm_base_verbose 100 \
	--mca btl_base_verbose 100 \
	--mca btl_ugni_verbose 100 \
	--mca pml_ucx_verbose 100 \
	--mca mtl_ofi_verbose 100 \
	--mca mtl_base_verbose 100 \
	--mca plm_alps_debug 1
endif

# TODO: NODES (and similar vars) should be part of the target name,
# and the recipe should extract it from there.

# default should be equivalent to ugni
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-default.log: \
	MPIRUN_TP_ARGS+=
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ugni.log: \
	MPIRUN_TP_ARGS+=--mca pml_ob1_priority 100
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ucx.log: \
	MPIRUN_TP_ARGS+=\
		--mca pml ucx \
		--mca pml_ucx_priority 100
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ofi.log: \
	MPIRUN_TP_ARGS+=\
		--mca mtl ofi \
		--mca mtl_ofi_priority 100 \
		--mca pml_ucx_priority 0
# Also works: --mca btl_tcp_if_include 10.128.0.0/14
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp.log: \
	MPIRUN_TP_ARGS+=\
		--mca btl self,tcp \
		--mca btl_tcp_if_include ipogif0

$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-%.log: | $(DATA_DIR)/
	$(EPREFIX)/usr/bin/osubench '$(PATTERN)' '$(PATTERN_EXCLUDE)' \
		mpirun -n "$(NODES)" --map-by "$(subst -,:,$(MAP_BY))" \
		$(MPIRUN_ARGS) $(MPIRUN_TP_ARGS)
.PHONY: run

DEBUG_Q=debug-cache-quad

%/job: | $(DATA_DIR)/
	rm -f $*.{cobaltlog,output,error}
	touch $*.{cobaltlog,output,error}
	qsub -O "$*" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ "$(NODES)" -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$(EPREFIX)/startprefix -c "env \
		PATTERN='$(PATTERN)' PATTERN_EXCLUDE='$(PATTERN_EXCLUDE)' \
		make -C $${PWD} NODES=$(NODES) MAP_BY=$(MAP_BY) \
		MPIRUN_ARGS='$(MPIRUN_ARGS)' VERBOSE=$(VERBOSE) \
		DATA_DIR=$(DATA_DIR) \
		$*"
	$(if $(BLOCK),,exit 0 &&) tail -f $*.{cobaltlog,output,error}

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: job
