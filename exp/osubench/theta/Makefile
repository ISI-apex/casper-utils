ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Gentoo Prefix)
endif

CASPER_UTILS_ROOT:=$(abspath ../../..)

NOLOCAL?=1

DBG_Q_MAX_NODES:=8
MAIN_Q_MIN_NODES:=128
DEBUG_Q=debug-cache-quad
QUEUE?=

DATA_DIR?=$(firstword $(subst /, ,$(firstword $(MAKECMDGOALS))))

ifeq ($(QUEUE),debug)
QUEUE_ARG:=$(DEBUG_Q)
else
QUEUE_ARG:=$(QUEUE)
endif

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
     $(DATA_DIR)/osubench_ranks-2_tpn-1_mapby-node_tp-default.log
# TODO: concurrent job targets not supported, b/c need to block qsub
#     $(DATA_DIR)/osubench_ranks-2_tpn-1_mapby-node_tp-tcp.log

all: $(DATS)

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
$(DATA_DIR)/osubench_%_tp-default.log: \
	MPIRUN_TP_ARGS+=
$(DATA_DIR)/osubench_%_tp-ugni.log: \
	MPIRUN_TP_ARGS+=--mca pml_ob1_priority 100
$(DATA_DIR)/osubench_%_tp-ucx.log: \
	MPIRUN_TP_ARGS+=\
		--mca pml ucx \
		--mca pml_ucx_priority 100
$(DATA_DIR)/osubench_%_tp-ofi.log: \
	MPIRUN_TP_ARGS+=\
		--mca mtl ofi \
		--mca mtl_ofi_priority 100 \
		--mca pml_ucx_priority 0
# NOTE: ipogif0 iface has two addresses and only 10.128.x.x/14 is pingable,
# must use exclude directive (since 10.128.0.0/14 mask matches both)
$(DATA_DIR)/osubench_%_tp-tcp.log: \
	MPIRUN_TP_ARGS+=\
		--mca btl self,tcp \
		--mca btl_tcp_if_exclude lo,10.237.0.0/16 \
		--mca oob_tcp_if_exclude lo,10.237.0.0/16

define calc
$(strip $(shell echo '$(1)' | bc))
endef

define is-dbg-q
$(findstring debug,$(QUEUE_ARG))
endef

# dat/foo+bar --> foo
define first-tgt
$(firstword $(subst +, ,$(firstword $(1))))
endef

# tgt-extract(key, target_name) -> value
define tgt-extract
$(strip $(subst $(1)-,,$(filter $(1)-%,$(subst _, ,$(subst ., ,$(2))))))
endef

define gen-map-by
$(subst -,:,$(1))$(if $(NOLOCAL),:NOLOCAL)
endef

# tgt-nodes(target_name) -> node count (from: ranks/tasks_per_node)
define tgt-nodes
$(call calc,$(call tgt-extract,ranks,$(1)) / $(call tgt-extract,tpn,$(1)))
endef
define cap-job-nodes
$(if $(call is-dbg-q),\
	$(if $(filter 1,$(call calc,$(1) <= $(DBG_Q_MAX_NODES))),\
		$(1),$(error Debug queue allows only up to $(DBG_Q_MAX_NODES) nodes)),\
	$(if $(filter 1,$(call calc,$(MAIN_Q_MIN_NODES) < $(1))),\
		$(1),$(MAIN_Q_MIN_NODES)))
endef
define job-nodes
$(strip $(call cap-job-nodes,$(call tgt-nodes,$(call first-tgt,$(1)))))
endef

# Only one job at a time allowed in debug queue
ifneq ($(call is-dbg-q),)
.NOTPARALLEL:
endif

ifeq ($(IN),1)
$(DATA_DIR)/osubench_%.log: | $(DATA_DIR)/
	$(EPREFIX)/usr/bin/osubench '$(PATTERN)' '$(PATTERN_EXCLUDE)' \
		mpirun -n "$(call tgt-extract,ranks,$*)" \
		--map-by "$(call gen-map-by,$(call tgt-extract,mapby,$*))" \
		$(MPIRUN_ARGS) $(MPIRUN_TP_ARGS) | tee "$@"
# within the job, must run each target sequentially (nodes are shared)
.NOTPARALLEL:
else # IN=0
# Accepts multiple targets in a single job: make dat/foo.log+dat/bar.log
$(DATA_DIR)/%: | $(DATA_DIR)/
	rm -f $@.{cobaltlog,output,error}
	touch $@.{cobaltlog,output,error}
	qsub -O "$@" -n "$(or $(NODES),$(call job-nodes,$*))" \
		-t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(EPREFIX)/startprefix -c "env \
		PATTERN='$(PATTERN)' PATTERN_EXCLUDE='$(PATTERN_EXCLUDE)' \
		make -C $(CURDIR) IN=1 DATA_DIR=$(DATA_DIR) \
		MPIRUN_ARGS='$(MPIRUN_ARGS)' VERBOSE=$(VERBOSE) \
		$(patsubst %,$(DATA_DIR)/%,$(subst +, ,$*))"
	$(if $(BLOCK),,exit 0 &&) tail -f $@.{cobaltlog,output,error}

job:
	qsub -n "$(or $(NODES),2)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$(call make-q-arg,$(QUEUE)) $(QSUB_ARGS) --attr enable_ssh=1 -I
.PHONY: job
endif # IN
