#%:
#	$(MAKE) -f ../Makefile CC=mpicc CXX=mpic++ $*

include ../Makefile

PATTERN?=.*

dat/:
	mkdir -p $@

all: | dat/ \
	dat/bench-n-2-N-1.log \
	dat/bench-n-2-N-16.log

# run-rule(ranks-per-node)
define run-rule
dat/bench-n-%-N-$(1).log: | dat/
	DIR="$(abspath $(INSTALL_PATH))" ../osubench "$(PATTERN)" \
	srun -n "$$*" -N "$(1)" --mem 0 --cpu_bind=no 2>&1 | tee "$$@"
endef

$(foreach ranks_per_node,1 16,\
	$(eval $(call run-rule,$(ranks_per_node))))

CONSTRAINT?=xeon-2640v4
MAX_TIME_MIN?=59

# Defaults for interactive job only (target: 'job')
NODES?=2
NTASKS_PER_NODE?=16

%/job:
	touch $*.{out,err}
	sbatch --output $*.out --error $*.err \
		--constraint "$(CONSTRAINT)" --mem 0 \
		--time 00:$(MAX_TIME_MIN):00  \
		$$(echo $* | sed \
			's@\s*dat/bench-n-\([0-9]\+\)-N-\([0-9]\+\).log\s*@--nodes \1 --ntasks-per-node \2@') \
		exec.sh make PATTERN="$(PATTERN)" $*
	tail -f $*.{out,err}

job:
	salloc --nodes "$(NODES)" \
		--ntasks-per-node "$(NTASKS_PER_NODE)" \
		--constraint "$(CONSTRAINT)" --mem 0 \
	--time 00:$(MAX_TIME_MIN):00
.PHONY: job
