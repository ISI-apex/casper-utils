EPREFIX_REQUIRED?=1
ifeq ($(EPREFIX_REQUIRED),1)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
endif # EPREFIX_REQUIRED
ifeq ($(ACCOUNT),)
$(error ACCOUNT env var not set to ANL Theta billing account name)
endif # ACCOUNT

MAX_TIME?=
ACCOUNT?=
MONITOR?=0
SUPPRESS_RC?=
TASKS?=
# Print peak memory usage every N seconds
MONITOR_MEM?=
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

include $(EPREFIX)/usr/lib/prefix-tools/make/Makefile.job

define is-dbg-q
$(findstring debug,$(QUEUE_ARG))
endef

ifeq ($(IN),)
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

# Only one job at a time allowed in debug queue
ifneq ($(call is-dbg-q),)
.NOTPARALLEL:
endif

# Accepts multiple targets in a single job: make dat/foo.log+bar.log
# Re JOB_NAME: Ideally we would just use the top-level target name, but
# when multiple targets are combined into one job, the top-level target
# name gets too long.
.ONESHELL:
$(DATA_DIR)/%: | $(DATA_DIR)/
	JOB_NAME="$(DATA_DIR)/job.$$(date +%Y%m%d%H%M%S).$$$$"
	@echo JOB_NAME=$${JOB_NAME}
	echo $@ > $${JOB_NAME}.tgt
	MONITOR=$(MONITOR) SUPPRESS_RC=$(SUPPRESS_RC) \
	$(PTOOLS_HOST)/pbsub -J "$${JOB_NAME}" \
		-o "$${JOB_NAME}.log" \
		-P "$(ACCOUNT)" \
		-nnodes "$(call job-nodes-arg,$*)" \
		-W "$(call max-time-arg,$*)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(BSUB_ARGS) \
		-- \
		env LOG=$${JOB_NAME}.dvmlog \
		dvmrun --report-uri "$${JOB_NAME}.dvmuri" \
		-- \
		make -j -k -C $(CURDIR) IN=1 \
		DVM_URI_FILE="$${JOB_NAME}.dvmuri" \
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
