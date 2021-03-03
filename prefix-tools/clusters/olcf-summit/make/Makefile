EPREFIX_REQUIRED?=1
ifeq ($(EPREFIX_REQUIRED),1)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
endif # EPREFIX_REQUIRED
ifeq ($(ACCOUNT),)
$(error ACCOUNT env var not set to ANL Theta billing account name)
endif # ACCOUNT

MAKEFLAGS+=--keep-going

PTOOLS:=$(EPREFIX)/ptools

# 0 max time means maximum allowed
MAX_TIME?=
ACCOUNT?=
MONITOR?=0
SUPPRESS_RC?=
NOLOCAL?=1
OVERSUBSCRIBE?=
DISPLAYMAP?=
TASKS?=
DEDI_NODE_FOR_RANK0?=1
# Print peak memory usage every N seconds
MONITOR_MEM?=

MPIRUN_INTERNAL_ARGS:=--bind-to none

MEM_PER_NODE?=510G

# Debug Q max nodes is 'unlimited' on Summit
DBG_Q_MAX_NODES:=
MAIN_Q_MIN_NODES:=1
DEBUG_Q=debug
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

$(DATA_DIR)/:
	mkdir -p $@

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
$(DATA_DIR)/$(1)^split: $(patsubst %,$(DATA_DIR)/%,$(2)) ;
endef
define target-set
$(eval $(call target-set-rule,$(1),$(2)))
endef

DEFINE:=define
define BC_FUNCS
$(DEFINE) ceil(x) {\n
  auto os,xx;x=-x;os=scale;scale=0\n
  xx=x/1;if(xx>x).=xx--\n
  scale=os;return(-xx)\n
}\n
scale=4;\n
endef
define calc
$(strip $(shell echo -e '$(BC_FUNCS)' '$(1)' | bc))
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

# tgt-extract(key, target_name [, is_optional]) -> value
define tgt-extract
$(strip $(if $(findstring $(1),$(2)),\
	$(subst $(1)-,,$(filter $(1)-%,$(subst _, ,$(subst ., ,$(2))))),
	$(if $(3),,$(error Field $(1) not in target name))))
endef

COMMA:=,

# tgt-steps(target_name) -> comma-separated list of step names
define tgt-steps
$(strip $(subst -,$(COMMA),$(call tgt-extract,steps,$(1),optional)))
endef

define gen-map-by-mods
$(strip $(if $(NOLOCAL),:NOLOCAL)$(if $(OVERSUBSCRIBE),:OVERSUBSCRIBE)$(if $(DISPLAYMAP),:DISPLAY))
endef

# tgt-tasks-per-node(target_name)
define tgt-tasks-per-node
$(strip $(call tgt-extract,tpn,$(1)))
endef

# tgt-nodes(target_name) -> node count (from: ranks/tasks_per_node)
# +1 extra node for dedicating to rank 0
# +1 for extra node for NOLOCAL workaround (see comment near hostfile below)
define tgt-nodes
$(strip \
  $(if $(DEDI_NODE_FOR_RANK0),\
    $(call calc,\
      2 + ceil(($(call tgt-extract,ranks,$(1))-1) / \
	$(call tgt-tasks-per-node,$(1)))),\
    $(call calc,\
      ceil($(call tgt-extract,ranks,$(1)) / $(call tgt-tasks-per-node,$(1))))))
endef

ifeq ($(IN),)
define cap-job-nodes
$(if $(call is-dbg-q),\
	$(if $(DBG_Q_MAX_NODES),\
		$(if $(filter 1,$(call calc,$(1) <= $(DBG_Q_MAX_NODES))),\
			$(1),$(error Debug queue allows only up to $(DBG_Q_MAX_NODES) nodes)),\
		$(1)),\
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
# https://docs.olcf.ornl.gov/systems/summit_user_guide.html#job-priority-by-processor-count
define max-time-for-nodes
$(if $(call greater-eq,$(1),922),24:00:00,\
$(if $(call greater-eq,$(1),92),12:00:00,\
$(if $(call greater-eq,$(1),46),6:00:00,\
$(if $(call greater-eq,$(1),1),2:00:00,\
$(if $(call is-dbg-q),02:00:00,\
    $(error Nodes below min allocation and not on debug queue: $(1))))))))
endef
endif # IN

ifeq ($(IN),)
# Only one job at a time allowed in debug queue
ifneq ($(call is-dbg-q),)
.NOTPARALLEL:
endif
endif # IN

$(DATA_DIR)/prun_%.rankfile: | $(DATA_DIR)/
	mapranks --ranks "$(call tgt-extract,ranks,$*)" \
		--ranks-per-node "$(call tgt-tasks-per-node,$*)" \
		$(if $(DEDI_NODE_FOR_RANK0),--dedicate-node-to-rank0) "$@"

ifneq ($(IN),)
# prun-cmd(target-stem, rankfile)
define prun-cmd
prun -n "$(call tgt-extract,ranks,$(1))" \
    --map-by "rankfile:FILE=$(2)$(call gen-map-by-mods)" \
    $(MPIRUN_ARGS) $(MPIRUN_INTERNAL_ARGS)
endef
# Example usage from the consumer makefile:
#$(DATA_DIR)/ch_%.csv: $(DATA_DIR)/prun_%.hostfile | $(DATA_DIR)/
#	set -o pipefail; \
#	$(call prun-cmd,$*,$<) ./app.sh 2>&1 | tee "$@.log"
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
	JOB_NAME="$(DATA_DIR)/job.$$(date +%Y%m%d%H%M%S).$$$$"
	echo JOB_NAME=$${JOB_NAME}
	echo $@ > $${JOB_NAME}.tgt
	MONITOR=$(MONITOR) SUPPRESS_RC=$(SUPPRESS_RC) \
	$(PTOOLS)/pbsub -J "$${JOB_NAME}" -o "$${JOB_NAME}.log" \
		-P "$(ACCOUNT)" \
		-nnodes "$(call job-nodes-arg,$*)" \
		-W "$(call max-time-arg,$*)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(BSUB_ARGS) \
		-- \
		env LOG=$${JOB_NAME}.dvmlog \
		dvmrun \
		-- \
		make -j -k -C $(CURDIR) IN=1 \
		DATA_DIR=$(DATA_DIR) MPIRUN_ARGS='$(MPIRUN_ARGS)' \
		VERBOSE=$(VERBOSE) TASKS=$(TASKS) \
		NOLOCAL=$(NOLOCAL) \
		OVERSUBSCRIBE=$(OVERSUBSCRIBE) \
		DISPLAYMAP=$(DISPLAYMAP) \
		DEDI_NODE_FOR_RANK0=$(DEDI_NODE_FOR_RANK0) \
		MEM_PER_NODE=$(MEM_PER_NODE) \
		MONITOR_MEM=$(MONITOR_MEM) \
		$(patsubst %,$(DATA_DIR)/%,$(subst +, ,$*))

job:
	bsub -P "$(ACCOUNT)" -nnodes "$(or $(NODES),2)" -W "$(MAX_TIME)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(BSUB_ARGS) -Is /bin/bash
.PHONY: job
endif # IN

.SECONDARY: