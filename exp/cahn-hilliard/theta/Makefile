ifeq ($(filter %.pdf %.svg,$(MAKECMDGOALS)),)

ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif

endif # MAKECMDGOALS

MAKEFLAGS+=--keep-going

# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

PTOOLS:=$(EPREFIX)/ptools
# 0 max time means maximum allowed
MAX_TIME?=
ACCOUNT?=CASPER
MONITOR?=0
SUPPRESS_RC?=
SSH?=
NOLOCAL?=1
OVERSUBSCRIBE?=
DISPLAYMAP?=
TASKS?=
# --host +e: request empty nodes (do not share nodes among prun jobs)
MPIRUN_INTERNAL_ARGS:=--bind-to none --host +e

# MAX_SLOTS_PER_NODE is only used for --map-by core.  It is not clear how
# '--map-by core' knows how many slots there are per node, but the setting
# of MAX_SLOTS_PER_NODE must match whatever '--map-by core' does. We set
# this var to max physical cores, assuming --map-by core defaults to number
# of physical cores per node.  The value of this variable is ignored by
# *-ppr-N-node targets, which set the param to N. For other targets, this
# value determines how many nodes to request (based on how many ranks in the
# target).
MAX_SLOTS_PER_NODE?=64
# The '--map-by core' appears to be incompatible with --host
# +e, so default to ppr-N-node for most targets.
MAPBY?=ppr-$(MAX_SLOTS_PER_NODE)-node
MEM_PER_NODE:=190G

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

# Fits on 8 nodes of debug q in parallel
DATS_ch-core-tiny=\
	ch_mesh-128_ranks-16_mapby-$(MAPBY).csv \
	ch_mesh-128_ranks-32_mapby-$(MAPBY).csv \
	ch_mesh-128_ranks-48_mapby-$(MAPBY).csv \
	ch_mesh-128_ranks-64_mapby-$(MAPBY).csv \

$(call target-set,ch-core-tiny,$(DATS_ch-core-tiny))

DATS_ch-mem=\
	ch_mesh-256_ranks-16_mapby-$(MAPBY).csv \
	ch_mesh-128_ranks-32_mapby-$(MAPBY).csv \

$(call target-set,ch-mem,$(DATS_ch-mem))

# Together with ch-core-tiny, < 1 hr total (fits on dbg q in sequence)
DATS_ch-core-small=\
	ch_mesh-96_ranks-4_mapby-$(MAPBY).csv \
	ch_mesh-96_ranks-8_mapby-$(MAPBY).csv \
	ch_mesh-96_ranks-16_mapby-$(MAPBY).csv \
	ch_mesh-96_ranks-32_mapby-$(MAPBY).csv \
	ch_mesh-96_ranks-64_mapby-$(MAPBY).csv \
	ch_mesh-256_ranks-32_mapby-$(MAPBY).csv \
	ch_mesh-256_ranks-48_mapby-$(MAPBY).csv \
	ch_mesh-256_ranks-64_mapby-$(MAPBY).csv \
	ch_mesh-512_ranks-48_mapby-$(MAPBY).csv \
	ch_mesh-512_ranks-64_mapby-$(MAPBY).csv \
	ch_mesh-512_ranks-96_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-96_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-128_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-192_mapby-$(MAPBY).csv \

$(call target-set,ch-core-small,$(DATS_ch-core-small))

# hypothesis: < 1 hr each (so can run via the /split target on debug q)
DATS_ch-core-large=\
	ch_mesh-2048_ranks-128_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-192_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-256_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-320_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-384_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-512_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-128_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-192_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-256_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-320_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-384_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-448_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-512_mapby-$(MAPBY).csv \

$(call target-set,ch-core-large,$(DATS_ch-core-large))

$(call target-set,ch-core-8nodes,\
  $(DATS_ch-core-small) $(DATS_ch-core-large))

DATS_ch-core-jumbo=\
	ch_mesh-2048_ranks-768_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-768_mapby-$(MAPBY).csv \

# segfault
#	ch_mesh-2048_ranks-1024_mapby-$(MAPBY).csv \
#	ch_mesh-4096_ranks-1024_mapby-$(MAPBY).csv \

# OOM
#	ch_mesh-6144_ranks-256_mapby-$(MAPBY).csv \
#	ch_mesh-6144_ranks-512_mapby-$(MAPBY).csv \
#	ch_mesh-6144_ranks-768_mapby-$(MAPBY).csv \
#	ch_mesh-6144_ranks-1024_mapby-$(MAPBY).csv \
#	ch_mesh-6144_ranks-2048_mapby-$(MAPBY).csv \

#	ch_mesh-8192_ranks-768_mapby-$(MAPBY).csv \
#	ch_mesh-8192_ranks-1024_mapby-$(MAPBY).csv \
#	ch_mesh-8192_ranks-2048_mapby-$(MAPBY).csv \
#	ch_mesh-8192_ranks-4096_mapby-$(MAPBY).csv \

#	ch_mesh-12288_ranks-1024_mapby-$(MAPBY).csv \
#	ch_mesh-12288_ranks-2048_mapby-$(MAPBY).csv \
#	ch_mesh-12288_ranks-4096_mapby-$(MAPBY).csv \

$(call target-set,ch-core-jumbo,$(DATS_ch-core-jumbo))

# These were collected on debug q (some only mesh+setup, without solve), but
# perhaps are not of critical interest
DATS_ch-core-jumbo-extra=\
	ch_mesh-128_ranks-8_mapby-$(MAPBY).csv \
	ch_mesh-256_ranks-8_mapby-$(MAPBY).csv \
	ch_mesh-256_ranks-16_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-16_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-32_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-48_mapby-$(MAPBY).csv \
	ch_mesh-1024_ranks-64_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-64_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-128_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-384_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-448_mapby-$(MAPBY).csv \
	ch_mesh-2048_ranks-512_mapby-$(MAPBY).csv \
	ch_mesh-4096_ranks-64_mapby-$(MAPBY).csv \

$(call target-set,ch-core-jumbo-extra,$(DATS_ch-core-jumbo-extra))

DATS_ch-core=$(DATS_ch-core-tiny) $(DATS_ch-core-small) \
  $(DATS_ch-core-large) $(DATS_ch-core-jumbo)
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
define sum
$(call calc,$(patsubst %,% +,$(1)) 0)
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

# tgt-extract(key, target_name) -> value
define tgt-extract
$(strip $(subst $(1)-,,$(filter $(1)-%,$(subst _, ,$(subst ., ,$(2))))))
endef

define gen-map-by
$(subst -,:,$(1))$(if $(NOLOCAL),:NOLOCAL)$(if $(OVERSUBSCRIBE),:OVERSUBSCRIBE)$(if $(DISPLAYMAP),:DISPLAY)
endef

# tgt-tasks-per-node(target_name)
# Extracts N from ppr-N-node within the target name.
# Only ppr-N-node is supported, not other ppr-N-*.
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

ifeq ($(IN),)
define cap-job-nodes
$(if $(call is-dbg-q),\
	$(if $(filter 1,$(call calc,$(1) <= $(DBG_Q_MAX_NODES))),\
		$(1),$(error Debug queue allows only up to $(DBG_Q_MAX_NODES) nodes)),\
	$(if $(filter 1,$(call calc,$(MAIN_Q_MIN_NODES) < $(1))),\
		$(1),$(MAIN_Q_MIN_NODES)))
endef
define required-nodes
$(strip $(call sum,\
  $(foreach t,$(call split-targets,$(1)),$(call tgt-nodes,$(t)))))
endef
define job-nodes
$(strip $(call cap-job-nodes,$(call required-nodes,$(1))))
endef
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
endif # IN

ifeq ($(IN),)
# Only one job at a time allowed in debug queue
ifneq ($(call is-dbg-q),)
.NOTPARALLEL:
endif
endif # IN

ifneq ($(IN),)
$(DATA_DIR)/ch_%.csv: | $(DATA_DIR)/
	set -o pipefail; \
	prun -n "$(call tgt-extract,ranks,$*)" \
		--map-by "$(call gen-map-by,$(call tgt-extract,mapby,$*))" \
		$(MPIRUN_ARGS) $(MPIRUN_INTERNAL_ARGS) \
		env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
		bash $(PWD)/fch.sh "$(call tgt-extract,mesh,$*)" \
			"$(call tgt-extract,ranks,$*)" \
			"$(call tgt-tasks-per-node,$*)" --elapsed-out "$@" \
			--mem-per-node "$(MEM_PER_NODE)"
			$(if $(TASKS),--tasks "$(TASKS)") \
		2>&1 | tee "$@.log"
else # IN=0
define expanded-targets
$(or $(DATS),$(1))
endef
define job-nodes-ovr
$(strip $(or $(NODES),$(call job-nodes,$(call expanded-targets,$(1)))))
endef
# job-nodes-arg(target_name)
define job-nodes-arg
$(strip $(info Nodes required for $(1): \
  $(call required-nodes,$(call expanded-targets,$(1))))\
$(call job-nodes-ovr,$(1)))
endef
# max-time(target_name) -> max allowed job time limit
define max-time-arg
$(strip $(or $(MAX_TIME),\
    $(call max-time-for-nodes,$(call job-nodes-ovr,$(1)))))
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
	$(PTOOLS)/pqsub -O "$${JOB_NAME}" -A "$(ACCOUNT)" \
		-n "$(call job-nodes-arg,$*)" -t "$(call max-time-arg,$*)" \
		$(if $(SSH),--attr enable_ssh=1) \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) \
		-- \
		env LOG=$${JOB_NAME}.dvmlog dvmrun \
		  -- \
		make -j -k -C $(CURDIR) IN=1 \
		DATA_DIR=$(DATA_DIR) MPIRUN_ARGS='$(MPIRUN_ARGS)' \
		VERBOSE=$(VERBOSE) TASKS=$(TASKS) \
		$(patsubst %,$(DATA_DIR)/%,$(subst +, ,$*))

job:
	qsub -A "$(ACCOUNT)" -n "$(or $(NODES),2)" -t "$(MAX_TIME)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) --attr enable_ssh=1 -I
.PHONY: job
endif # IN

.SECONDARY:
