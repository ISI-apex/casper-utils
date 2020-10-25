CASPER_UTILS_ROOT:=$(abspath ../../../..)

NODES?=2
MAX_TIME_MIN?=30

ACCOUNT?=CASPER
DEBUG_Q=debug-cache-quad

#include ../Makefile
all:
	$(MAKE) -C ..

run:
	PATH=$(CASPER_UTILS_ROOT)/bin/theta:$${PATH} \
	mpirun -n "$(NODES)" --map-by node command ../mpitest

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: job
