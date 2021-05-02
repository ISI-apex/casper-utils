EPREFIX_REQUIRED?=1
ifeq ($(EPREFIX_REQUIRED),1)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
endif # EPREFIX_REQUIRED
ifeq ($(ACCOUNT),)
$(error ACCOUNT env var not set to ANL Theta billing account name)
endif # ACCOUNT

# 0 max time means maximum allowed
MAX_TIME?=
ACCOUNT?=
MONITOR?=0
SUPPRESS_RC?=
SSH?=
TASKS?=
# Print peak memory usage every N seconds
MONITOR_MEM?=

MEM_PER_NODE?=190G

DBG_Q_MAX_NODES:=8
MAIN_Q_MIN_NODES:=128
DEBUG_Q=debug-cache-quad
QUEUE?=

ifeq ($(QUEUE),debug)
QUEUE_ARG:=$(DEBUG_Q)
else
QUEUE_ARG:=$(QUEUE)
endif

define is-dbg-q
$(findstring debug,$(QUEUE_ARG))
endef

include $(EPREFIX)/usr/lib/prefix-tools/make/Makefile.job

COMMA:=,

ifeq ($(IN),)
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
	echo JOB_NAME=$${JOB_NAME}
	echo $@ > $${JOB_NAME}.tgt
	MONITOR=$(MONITOR) SUPPRESS_RC=$(SUPPRESS_RC) \
	$(PTOOLS_HOST)/pqsub -O "$${JOB_NAME}" -A "$(ACCOUNT)" \
		-n "$(call job-nodes-arg,$*)" -t "$(call max-time-arg,$*)" \
		$(if $(SSH),--attr enable_ssh=1) \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) \
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
	qsub -A "$(ACCOUNT)" -n "$(or $(NODES),2)" -t "$(MAX_TIME)" \
		$(if $(QUEUE_ARG),-q $(QUEUE_ARG)) \
		$(QSUB_ARGS) --attr enable_ssh=1 -I
.PHONY: job
endif # IN
