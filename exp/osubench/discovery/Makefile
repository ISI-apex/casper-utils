#include ../Makefile

ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

CASPER_UTILS_ROOT:=$(abspath ../../..)

CLUSTER?=discovery:debug
ARCH?=ivybridge

# Ideally these would be part of target name (and recipes would extract
# them from the target name), but that's too complicated to implement.
NODES?=2
TASKS_PER_NODE?=1
MAP_BY?=node
BLOCK?=

# By default, include all except one-sided benchmarks (observed hang from
# within prefix, although need to retest), and exclude multi-threaded
# bechmarks because they either take very long or even hang in an infinite
# loop/deadlock (unclear).
PATTERN?=pt2pt|collective|startup
PATTERN_EXCLUDE?=_mt$$

MAX_TIME_MIN?=30
ACCOUNT?=CASPER

DATA_DIR?=dat

MPIRUN_ARGS?=

ifneq ($(VERBOSE),)
	MPIRUN_TP_ARGS+=\
		--mca btl_base_verbose 100 \
		--mca pml_base_verbose 100 \
		--mca pml_ucx_verbose 100
endif

all: \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-ib0.log/job \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-eth0.log/job \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-default.log/job

.NOTPARALLEL:

$(DATA_DIR)/:
	mkdir -p "$@"

$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-%.log: \
	MPIRUN_TP_ARGS+=--mca btl self,tcp --mca pml_ucx_priority 0

$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-eth0.log: \
	MPIRUN_TP_ARGS+=--mca btl_tcp_if_include eth0
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-ib0.log: \
	MPIRUN_TP_ARGS+=--mca btl_tcp_if_include ib0

$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ucx-%.log: \
	MPIRUN_TP_ARGS+=--mca pml ucx
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ucx-ud.log: \
	MPIRUN_TP_ARGS+=-x UCX_TLS=sm,ud_verbs
# NOTE: rc_verbs fails ("no auxiliary transport")
# TODO: potentially this only happens without Connection Mgr (ucx_ib_cm)?
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-ucx-rc.log: \
	MPIRUN_TP_ARGS+=-x UCX_TLS=sm,rc_verbs
# could add for experimentation: -x UCX_NET_DEVICES=mlx4_0:1

# should be the same as ucx-default (== ucx-ud?)
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-default.log: \
	MPIRUN_TP_ARGS+=

# To be run from within EPREFIX
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-%.log: | $(DATA_DIR)/
	osubench '$(PATTERN)' '$(PATTERN_EXCLUDE)' \
		mpirun -n "$(NODES)" --map-by "$(MAP_BY)" \
		$(MPIRUN_ARGS) $(MPIRUN_TP_ARGS) \
		2>&1 | tee $@

# pass regexp pattern args via env because may contain $
%/job: | $(DATA_DIR)/
	PATH=$(CASPER_UTILS_ROOT)/bin:$${PATH} \
	NONBLOCK=$(if $(BLOCK),,1) \
	psbatch "$(EPREFIX)" "$(CLUSTER)" "$(ARCH)" all \
		"$(NODES)" "$(TASKS_PER_NODE)" "00:$(MAX_TIME_MIN):00" \
		env "PATTERN='$(PATTERN)'" \
		"PATTERN_EXCLUDE='$(PATTERN_EXCLUDE)'" \
		$$(which make) -C $${PWD} EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MAP_BY="$(MAP_BY)" \
		MPIRUN_ARGS="'$(MPIRUN_ARGS)'" VERBOSE="$(VERBOSE)" \
		$*

job: | $(DATA_DIR)/
	PATH=$(CASPER_UTILS_ROOT)/bin:$${PATH} \
	psalloc "$(EPREFIX)" "$(CLUSTER)" "$(ARCH)" all \
		"$(NODES)" "$(TASKS_PER_NODE)" "00:$(MAX_TIME_MIN):00" $*
.PHONY: job
