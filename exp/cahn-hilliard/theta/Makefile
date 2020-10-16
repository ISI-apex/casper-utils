ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif

MCA_ARGS:=--mca btl self,ugni --mca btl_tcp_if_include 10.128.0.0/16

all: dat/test-2-2-node.csv

dat/:
	mkdir -p $@

times-node: | dat/ \
	dat/times-32-2-node.csv \
	dat/times-96-2-node.csv

times-core: | dat/ \
	dat/times-96-2-core.csv \
	dat/times-96-4-core.csv \
	dat/times-96-8-core.csv \
	dat/times-96-16-core.csv \
	dat/times-96-32-core.csv \
	dat/times-96-64-core.csv \
	dat/times-128-32-core.csv \
	dat/times-128-48-core.csv \
	dat/times-128-64-core.csv \
	dat/times-256-48-core.csv \
	dat/times-256-64-core.csv \
	dat/times-512-48-core.csv \
	dat/times-512-64-core.csv \
	dat/times-1024-48-core.csv \
	dat/times-1024-64-core.csv \
	dat/times-1536-128-core.csv \
	dat/times-1536-192-core.csv

times-ppr-32-node: | dat/ \
	dat/times-512-64-ppr-32-node.csv \
	dat/times-1024-64-ppr-32-node.csv

define run
	PATH=$(PWD)/../../../bin/theta::$$$$PATH \
	     mpirun -n "$(2)" --map-by "$(3):NOLOCAL" $(MCA_ARGS) \
	     command bash $(PWD)/fch.sh "$(1)" --elapsed-out "$$@"
endef


define run-rule
dat/times-%-$(1)-$(2).csv: | dat/
	$(call run,$$*,$(1),$(2))
endef

$(foreach rank,2 4 8 16 32 48 64 128 192,\
	$(eval $(call run-rule,$(rank),node))\
	$(eval $(call run-rule,$(rank),core))\
	$(eval $(call run-rule,$(rank),ppr\:32\:node))\
)

NODES?=2
MAP_BY?=node
PATTERN?=.*
MAX_TIME_MIN?=59
ACCOUNT?=CASPER

DEBUG_Q=debug-cache-quad

%/job:
	rm -f $*.log.{cobaltlog,output,error}
	touch $*.log.{cobaltlog,output,error}
	qsub -O "$*.log" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ "$(NODES)" -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MAP_BY="$(MAP_BY)" PATTERN="$(PATTERN)" \
		MCA_ARGS="$(MCA_ARGS)" MPIRUN_ARGS="$(MPIRUN_ARGS)" \
		$*
	tail -f $*.log.{cobaltlog,output,error}

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: job
