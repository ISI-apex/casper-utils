#include ../Makefile

ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

CASPER_UTILS_ROOT:=$(abspath ../../..)
PTOOLS=$(EPREFIX)/ptools

CLUSTER?=discovery:debug
ARCH?=ivybridge

# Ideally these would be part of target name (and recipes would extract
# them from the target name), but that's too complicated to implement.
NODES?=2
TASKS_PER_NODE?=1
MAP_BY?=node
NOLOCAL?=
BLOCK?=

# By default, include all except one-sided benchmarks (observed hang from
# within prefix, although need to retest), and exclude multi-threaded
# bechmarks because they either take very long or even hang in an infinite
# loop/deadlock (unclear).
PATTERN?=pt2pt|collective|startup
PATTERN_EXCLUDE?=_mt$$

MAX_TIME_MIN?=30

DATA_DIR?=dat

MPIRUN_ARGS?=

ifneq ($(VERBOSE),)
MPIRUN_TP_ARGS+=\
	--mca btl_base_verbose 100 \
	--mca pml_base_verbose 100 \
	--mca pml_ucx_verbose 100
endif

define gen-map-by
$(subst -,:,$(1))$(if $(NOLOCAL),:NOLOCAL)
endef

all: \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-ib0.log/job \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-tcp-eth0.log/job \
	$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-default.log/job

# A shortcut for convenience
TEST_DIR=dat-test
TEST_ARGS=NODES=2 MAP_BY=node PATTERN=hello BLOCK=1 DATA_DIR=$(TEST_DIR)
TEST_TGT=$(TEST_DIR)/bench-prefix-n-2-map-by-node-default.log
test:
	rm -r $(TEST_DIR)
	$(MAKE) $(TEST_ARGS) $(TEST_TGT)

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

ifeq ($(IN),1)
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-%.log: | $(DATA_DIR)/
	osubench '$(PATTERN)' '$(PATTERN_EXCLUDE)' \
		mpirun -n "$(NODES)" \
		--map-by "$(call gen-map-by,$(MAP_BY))" \
		$(MPIRUN_ARGS) $(MPIRUN_TP_ARGS) \
		2>&1 | tee $@
else
# pass regexp pattern args via env because may contain $
$(DATA_DIR)/bench-prefix-n-$(NODES)-map-by-$(MAP_BY)-%.log: | $(DATA_DIR)/
	NONBLOCK=$(if $(BLOCK),,1) \
	LOG_DIR="$(CURDIR)/$(DATA_DIR)" LOG_NAME="$(@F)" \
	$(PTOOLS)/psbatch "$(CLUSTER)" "$(ARCH)" all \
		"$(NODES)" "$(TASKS_PER_NODE)" "00:$(MAX_TIME_MIN):00" \
		--job-name=osu_$(@F) \
		env "PATTERN='$(PATTERN)'" \
		"PATTERN_EXCLUDE='$(PATTERN_EXCLUDE)'" \
		$$(which make) -C "$(CURDIR)" IN=1 EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MAP_BY="$(MAP_BY)" \
		MPIRUN_ARGS="'$(MPIRUN_ARGS)'" VERBOSE="$(VERBOSE)" \
		DATA_DIR="$(DATA_DIR)" \
		"$@"

job: | $(DATA_DIR)/
	$(PTOOLS)/psalloc "$(CLUSTER)" "$(ARCH)" all \
		"$(NODES)" "$(TASKS_PER_NODE)" "00:$(MAX_TIME_MIN):00" $*
.PHONY: job
endif
