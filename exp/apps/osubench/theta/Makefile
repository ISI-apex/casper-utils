# On Theta, cc wrapper links mpi lib.
#%:
#	$(MAKE) -f ../Makefile CROSS_COMPILE=1 CC=cc CXX=cc $*

include ../Makefile

NODES?=2
RANKS_PER_NODE?=1
PATTERN?=.*
LOG=bench-n-$(NODES)-N-$(RANKS_PER_NODE).log
MAX_TIME_MIN?=25
ACCOUNT?=CASPER

$(LOG): run
run: $(INSTALL_PATH)/$(ARTIFACT)
	DIR="$(abspath $(INSTALL_PATH))" ../osubench "$(PATTERN)" \
	    aprun -n "$(NODES)" -N "$(RANKS_PER_NODE)" 2>&1 | tee "$(LOG)"
.PHONY: run

DEBUG_Q=debug-cache-quad
LOGS:=$(LOG).{cobaltlog,output,error}

run/job:
	rm -f $(LOGS)
	touch $(LOGS)
	qsub -O "$(LOG)" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ $(NODES) -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} \
		NODES="$(NODES)" RANKS_PER_NODE="$(RANKS_PER_NODE)" PATTERN="$(PATTERN)" run
	tail -f $(LOGS)
.PHONY: run/job

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" -q "$(DEBUG_Q)" \
		--attrs enable_ssh=1 -I
.PHONY: job
