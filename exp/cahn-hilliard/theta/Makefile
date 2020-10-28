ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif

MCA_ARGS:=--mca btl self,ugni --mca btl_tcp_if_include 10.128.0.0/16

# only one job allowed in the debug queue.
# TODO: serialize only debug queue targets, not production queue targets
.NOTPARALLEL:

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
	dat/times-1536-192-core.csv \
	dat/times-1536-256-core.csv

times-max: \
	dat/times-2048-256-core.csv \
	dat/times-2048-320-core.csv

times-ppr-node: | dat/ \
	dat/times-512-64-ppr-32-node.csv \
	dat/times-512-128-ppr-16-node.csv \
	dat/times-512-128-ppr-32-node.csv \
	dat/times-512-128-ppr-64-node.csv \
	dat/times-1024-64-ppr-32-node.csv

dat/times-512-%.csv/job: MAX_TIME_MIN=30
dat/times-1024-%.csv/job: MAX_TIME_MIN=45
dat/times-%-64-ppr-32-node.csv/job: NODES=2
dat/times-%-128-ppr-16-node.csv/job: NODES=8
dat/times-%-128-ppr-32-node.csv/job: NODES=4
dat/times-%-128-ppr-64-node.csv/job: NODES=2
dat/times-%-256-ppr-64-node.csv/job: NODES=4
dat/times-%-512-ppr-64-node.csv/job: NODES=8
dat/times-%-128-core.csv/job: NODES=2
dat/times-%-192-core.csv/job: NODES=3
dat/times-%-256-core.csv/job: NODES=4
dat/times-%-320-core.csv/job: NODES=5
dat/times-%-384-core.csv/job: NODES=6
dat/times-%-512-core.csv/job: NODES=8

define run
	mpirun -n "$(2)" --map-by "$(subst -,:,$(3)):NOLOCAL" $(MCA_ARGS) \
		env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
		bash $(PWD)/fch.sh "$(1)" --elapsed-out "$$@"
endef


define run-rule
dat/times-%-$(1)-$(2).csv: | dat/
	$(call run,$$*,$(1),$(2))
endef

$(foreach rank,2 4 8 16 32 48 64 128 192 256 320 384 512,\
	$(eval $(call run-rule,$(rank),node))\
	$(eval $(call run-rule,$(rank),core))\
	$(eval $(call run-rule,$(rank),ppr-16-node))\
	$(eval $(call run-rule,$(rank),ppr-32-node))\
	$(eval $(call run-rule,$(rank),ppr-64-node))\
)

NODES?=2
MAX_TIME_MIN?=59
ACCOUNT?=CASPER
SSH=
# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

DEBUG_Q=debug-cache-quad

%/job:
	rm -f $*.log.{cobaltlog,output,error}
	touch $*.log.{cobaltlog,output,error}
	qsub -O "$*.log" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$(if $(SSH),--attr enable_ssh=1) \
		$$([[ "$(NODES)" -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} EPREFIX=$(EPREFIX) \
		NODES="$(NODES)" MCA_ARGS="$(MCA_ARGS)" MPIRUN_ARGS="$(MPIRUN_ARGS)" \
		$*
	tail -f $*.log.{cobaltlog,output,error}

job:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		-q "$(DEBUG_Q)" --attr enable_ssh=1 -I
.PHONY: job
