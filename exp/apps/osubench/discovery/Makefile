include ../Makefile

CC=mpicc
CXX=mpic++

# Workaround for errors from runtime loader about incompatible
# libstdc++, which without this -rpath flag gets pulled in
# from /usr/lib64 instead of from /spack/.... (LD_LIBRARY_PATH
# does not help, loading gcc module does not help).
CC_VER:=8.3.0
ifeq ($(shell $(CC) --version | grep $(CC_VER)),)
$(error Compiler version assumed in Makefile $(CC_VER) differs from actual: update the Makefile)
endif
LDFLAGS+=-Wl,-rpath=/spack/apps/gcc/$(CC_VER)/lib64

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
	srun --ntasks "$$*" --ntasks-per-node "$(1)" --mem 0 --cpu_bind=no \
		--export=ALL 2>&1 | tee "$$@"
endef

$(foreach ranks_per_node,1 16,\
	$(eval $(call run-rule,$(ranks_per_node))))

CONSTRAINT?=xeon-2640v4
MAX_TIME_MIN?=59

# Defaults for interactive job only (target: 'job')
NODES?=2
NTASKS_PER_NODE?=16

%/job:
	rm -f $*.{out,err}
	touch $*.{out,err}
	sbatch --output $*.out --error $*.err \
		--constraint "$(CONSTRAINT)" --mem 0 \
		--time 00:$(MAX_TIME_MIN):00 \
		$$(echo $* | sed \
			's@\s*dat/bench-n-\([0-9]\+\)-N-\([0-9]\+\).log\s*@--ntasks \1 --ntasks-per-node \2@') \
		exec.sh make PATTERN="$(PATTERN)" $*
	tail -f $*.{out,err}

job:
	salloc --nodes "$(NODES)" \
		--ntasks-per-node "$(NTASKS_PER_NODE)" \
		--constraint "$(CONSTRAINT)" --mem 0 \
		--time 00:$(MAX_TIME_MIN):00
.PHONY: job
