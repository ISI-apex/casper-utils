ifeq ($(filter %.pdf %.svg,$(MAKECMDGOALS)),)

ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif

endif # MAKECMDGOALS

MAKEFLAGS+=--keep-going

# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

# 0 max time means maximum allowed
MAX_TIME?=
ACCOUNT?=CASPER
MONITOR?=0
SUPPRESS_RC?=
SSH?=
NOLOCAL?=1
TASKS?=
MPIRUN_INTERNAL_ARGS:=--bind-to none

# It is not clear how '--map-by core' knows how many slots there
# are per node, but the setting of MAX_SLOTS_PER_NODE must match
# whatever '--map-by core' does. We set this var to max physical cores,
# assuming --map-by core defaults to number of physical cores per node.
# The value of this variable is ignored by *-ppr-N-* targets, which
# set the param to N. For other targets, this value determines
# how many nodes to request (based on how many ranks in the target).
MAX_SLOTS_PER_NODE?=64

DBG_Q_MAX_NODES:=8
MAIN_Q_MIN_NODES:=128
DEBUG_Q=debug-cache-quad
QUEUE?=

ifeq ($(QUEUE),debug)
QUEUE_ARG:=$(DEBUG_Q)
else
QUEUE_ARG:=$(QUEUE)
endif

define strip-slash
$(patsubst %/,%,$(1))
endef
DATA_DIR?=$(call strip-slash,$(dir $(firstword $(MAKECMDGOALS))))
$(foreach t,$(MAKECMDGOALS),\
  $(if $(filter $(DATA_DIR),$(call strip-slash,$(dir $(t)))),,\
    $(error Targets have different data directory paths)))

all: ch-core-small ch-core-large

$(DATA_DIR)/:
	mkdir -p $@

include ../Makefile

EMPTY:=
SPACE:= $(EMPTY) $(EMPTY)
define combine-targets
$(DATA_DIR)/$(subst $(SPACE),+,$(strip $(foreach s,$(1),$(strip $(s)))))
endef
define split-targets
$(subst +,$(SPACE),$(patsubst $(DATA_DIR)/%,%,$(1)))
endef

define target-set-rule
$(DATA_DIR)/$(1): DATS=$(2)
$(DATA_DIR)/$(1): $(if $(IN),$(patsubst %,$(DATA_DIR)/%,$(2)))
$(DATA_DIR)/$(1)/split: $(patsubst %,$(DATA_DIR)/%,$(2)) ;
endef
define target-set
$(eval $(call target-set-rule,$(1),$(2)))
endef

DATS_ch-test=\
	ch_mesh-32_ranks-2_mapby-node.csv \

$(call target-set,ch-test,$(DATS_ch-test))

DATS_ch-node=\
	ch_mesh-32_ranks-2_mapby-node.csv \
	ch_mesh-96_ranks-2_mapby-node.csv \

$(call target-set,ch-node,$(DATS_ch-node))

# < 1 hr total
DATS_ch-core-small=\
	ch_mesh-96_ranks-4_mapby-core.csv \
	ch_mesh-96_ranks-8_mapby-core.csv \
	ch_mesh-96_ranks-16_mapby-core.csv \
	ch_mesh-96_ranks-32_mapby-core.csv \
	ch_mesh-96_ranks-64_mapby-core.csv \
	ch_mesh-128_ranks-16_mapby-core.csv \
	ch_mesh-128_ranks-32_mapby-core.csv \
	ch_mesh-128_ranks-48_mapby-core.csv \
	ch_mesh-128_ranks-64_mapby-core.csv \
	ch_mesh-256_ranks-32_mapby-core.csv \
	ch_mesh-256_ranks-48_mapby-core.csv \
	ch_mesh-256_ranks-64_mapby-core.csv \
	ch_mesh-512_ranks-48_mapby-core.csv \
	ch_mesh-512_ranks-64_mapby-core.csv \
	ch_mesh-512_ranks-96_mapby-core.csv \
	ch_mesh-1024_ranks-96_mapby-core.csv \
	ch_mesh-1024_ranks-128_mapby-core.csv \
	ch_mesh-1024_ranks-192_mapby-core.csv \

$(call target-set,ch-core-small,$(DATS_ch-core-small))

# hypothesis: < 1 hr each (so run via the /split target)
DATS_ch-core-large=\
	ch_mesh-2048_ranks-192_mapby-core.csv \
	ch_mesh-2048_ranks-256_mapby-core.csv \
	ch_mesh-2048_ranks-320_mapby-core.csv \
	ch_mesh-4096_ranks-384_mapby-core.csv \
	ch_mesh-4096_ranks-448_mapby-core.csv \
	ch_mesh-4096_ranks-512_mapby-core.csv \

$(call target-set,ch-core-large,$(DATS_ch-core-large))

# hypothesis: 8192 should take ~2hr (on ~16 nodes), 16384 ~4h (on ~32 nodes)
DATS_ch-core-jumbo=\
	ch_mesh-8192_ranks-768_mapby-core.csv \
	ch_mesh-8192_ranks-1024_mapby-core.csv \
	ch_mesh-8192_ranks-1280_mapby-core.csv \
	ch_mesh-12288_ranks-1280_mapby-core.csv \
	ch_mesh-12288_ranks-1536_mapby-core.csv \
	ch_mesh-12288_ranks-1792_mapby-core.csv \

#ch_mesh-16384_ranks-1536_mapby-core.csv \
#ch_mesh-16384_ranks-2048_mapby-core.csv \
#ch_mesh-16384_ranks-2560_mapby-core.csv \

$(call target-set,ch-core-jumbo,$(DATS_ch-core-jumbo))

DATS_ch-core=$(DATS_ch-core-small) $(DATS_ch-core-large)
$(call target-set,ch-core,$(DATS_ch-core))

# < 1 hr total
DATS_ch-ppr-node=\
	ch_mesh-1024_ranks-64_mapby-ppr-8-node.csv \
	ch_mesh-1024_ranks-64_mapby-ppr-16-node.csv \
	ch_mesh-1024_ranks-64_mapby-ppr-32-node.csv \
	ch_mesh-1024_ranks-64_mapby-ppr-48-node.csv \
	ch_mesh-1024_ranks-64_mapby-ppr-64-node.csv \

$(call target-set,ch-ppr-node,$(DATS_ch-ppr-node))

DEFINE:=define
define BC_FUNCS
$(DEFINE) ceil(x) {
  auto os,xx;x=-x;os=scale;scale=0
  xx=x/1;if(xx>x).=xx--
  scale=os;return(-xx)
}
scale=4;
endef
define calc
$(strip $(shell echo '$(BC_FUNCS)' '$(1)' | bc))
endef
define max
$(strip $(shell echo '$(1)' | xargs -n 1 echo | sort -nr | head -1))
endef
define greater-eq
$(filter $(call calc,$(1) >= $(2)),1)
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

# tgt-tasks-per-node(target_name)
# Extracts N from ppr-N within the target name
define tgt-tasks-per-node
$(strip $(if $(findstring mapby-ppr-,$(1)),\
	$(word 2,$(subst -, ,$(call tgt-extract,mapby,$(1)))),\
	$(if $(findstring mapby-node,$(1)),\
		1,\
		$(if $(findstring mapby-core,$(1)),\
			$(MAX_SLOTS_PER_NODE),\
			$(error Cannot determine tasks-per-node from mapby for $(1))))))
endef

# tgt-nodes(target_name) -> node count (from: ranks/tasks_per_node)
define tgt-nodes
$(call calc,ceil($(call tgt-extract,ranks,$(1)) / $(call tgt-tasks-per-node,$(1))))
endef
define cap-job-nodes
$(if $(call is-dbg-q),\
	$(if $(filter 1,$(call calc,$(1) <= $(DBG_Q_MAX_NODES))),\
		$(1),$(error Debug queue allows only up to $(DBG_Q_MAX_NODES) nodes)),\
	$(if $(filter 1,$(call calc,$(MAIN_Q_MIN_NODES) < $(1))),\
		$(1),$(MAIN_Q_MIN_NODES)))
endef
define job-nodes
$(strip $(call cap-job-nodes,$(call max,\
		$(foreach t,$(call split-targets,$(1)),\
			$(call tgt-nodes,$(t))))))
endef

# Only one job at a time allowed in debug queue and only one concurrent
# execution of mpirun allowed per job (regardless of which queue), since
# only one workload can run on the same set of resources for measurement.
# TODO: does mpirun accept multiple invocations in the same job
# allocations, and partition resources among the invocations?
ifneq ($(or $(IN),$(call is-dbg-q)),)
.NOTPARALLEL:
endif

ifeq ($(IN),1)
$(DATA_DIR)/ch_%.csv:
	set -o pipefail; \
	mpirun -n "$(call tgt-extract,ranks,$*)" \
		--map-by "$(call gen-map-by,$(call tgt-extract,mapby,$*))" \
		$(MPIRUN_ARGS) $(MPIRUN_INTERNAL_ARGS) \
		env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
		bash $(PWD)/fch.sh "$(call tgt-extract,mesh,$*)" \
			"$(call tgt-extract,ranks,$*)" \
			"$(call tgt-tasks-per-node,$*)" --elapsed-out "$@" \
			$(if $(TASKS),--tasks "$(TASKS)")
		2>&1 | tee "$@.log"
else # IN=0
# max-time-for-nodes(nodes) -> max allowed job time limit
# https://www.alcf.anl.gov/support-center/theta/job-scheduling-policy-theta
# Note: qsub -t 0 (which supposed to mean 'max allowed') does not work.
define max-time-for-nodes
$(if $(call greater-eq,$(1),802),24:00:00,\
$(if $(call greater-eq,$(1),640),12:00:00,\
$(if $(call greater-eq,$(1),384),9:00:00,\
$(if $(call greater-eq,$(1),256),6:00:00,\
$(if $(call greater-eq,$(1),128),3:00:00,\
$(if $(call is-dbg-q),01:00:00,\
    $(error Nodes below min allocation and not on debug queue: $(1))))))))
endef
# job-nodes-arg(target_name)
define job-nodes-arg
$(strip $(or $(NODES),$(call job-nodes,$(or $(DATS),$(1)))))
endef
# max-time(target_name) -> max allowed job time limit
define max-time-arg
$(strip $(or $(MAX_TIME),\
    $(call max-time-for-nodes,$(call job-nodes-arg,$(1)))))
endef

# Accepts multiple targets in a single job: make dat/foo.log+bar.log
# Re JOB_NAME: Ideally we would just use the top-level target name, but
# when multiple targets are combined into one job, the top-level target
# name gets too long.
.ONESHELL:
$(DATA_DIR)/%: | $(DATA_DIR)/
	JOB_NAME="$(DATA_DIR)/ch.$$(date +%Y%m%d%H%M%S).$$$$"
	echo JOB_NAME=$${JOB_NAME}
	echo $@ > $${JOB_NAME}.tgt
	MONITOR=$(MONITOR) SUPPRESS_RC=$(SUPPRESS_RC) \
	$(EPREFIX)/ptools/pqsub -O "$${JOB_NAME}" -A "$(ACCOUNT)" \
		-n "$(call job-nodes-arg,$*)" -t "$(call max-time-arg,$*)" \
		$(if $(SSH),--attr enable_ssh=1) \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) \
		-- make -C $(CURDIR) IN=1 DATA_DIR=$(DATA_DIR) \
		MPIRUN_ARGS='$(MPIRUN_ARGS)' VERBOSE=$(VERBOSE) \
		TASKS=$(TASKS) \
		$(patsubst %,$(DATA_DIR)/%,$(subst +, ,$*))

job:
	qsub -n "$(or $(NODES),2)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) --attr enable_ssh=1 -I
.PHONY: job
endif # IN
