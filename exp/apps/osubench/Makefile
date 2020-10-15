# Recipe for buliding OSU Micro Benchmarks for MPI on ANL Theta cluster

NAME=osu-micro-benchmarks
VER=5.6.3
TARBALL=$(NAME)-$(VER).tar.gz
DIR=$(NAME)-$(VER)
URL=https://mvapich.cse.ohio-state.edu/download/mvapich/$(TARBALL)
PREFIX=$(DIR)-prefix
# This var is not editable, it just set to what build system does by default
INSTALL_PATH=$(PREFIX)/libexec/$(NAME)

all: install

fetch: $(TARBALL)
$(TARBALL):
	curl -LRO $(URL) 
extract: $(DIR)
$(DIR): $(TARBALL)
	tar xf $(TARBALL)

# Use fake --build and --host to trick the build system into cross-compiling
# (Cray toolchain wrappers set tune flags, and make even conftest binaries
# generated during ./configure unrunnable on the build host.
ifneq ($(CROSS_COMPILE),)
CROSS_COMPILE_ARGS=--build=powerpc64-unknown-linux-gnu --host=x86_64-unknown-linux-gnu
endif
config: $(DIR)/config.status
$(DIR)/config.status: | $(DIR)
	cd $(DIR) && env CC=cc CXX=cc ./configure --prefix=$(abspath $(PREFIX)) \
		$(CROSS_COMPILE_ARGS) --disable-cuda --disable-openacc

ARTIFACT=mpi/startup/osu_hello
build: $(ARTIFACT) 
$(ARTIFACT): $(DIR)/config.status
	$(MAKE) -C $(DIR)

install: $(INSTALL_PATH)/$(ARTIFACT)
$(INSTALL_PATH)/$(ARTIFACT): $(DIR)/$(ARTIFACT)
	$(MAKE) -C $(DIR) install

NODES?=2
RANKS_PER_NODE?=1
PATTERN?=.*
LOG=bench-n-$(NODES)-N-$(RANKS_PER_NODE).log
MAX_TIME_MIN?=25
ACCOUNT?=CASPER

$(LOG): run
run: $(INSTALL_PATH)/$(ARTIFACT)
	DIR="$(abspath $(INSTALL_PATH))" ./osubench "$(PATTERN)" \
	    aprun -n "$(NODES)" -N "$(RANKS_PER_NODE)" 2>&1 | tee "$(LOG)"
.PHONY: run

DEBUG_Q=debug-cache-quad
LOGS:=$(LOG).{cobaltlog,output,error}

job:
	rm -f $(LOGS)
	touch $(LOGS)
	qsub -O "$(LOG)" -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" \
		$$([[ $(NODES) -lt 128 ]] && echo -q $(DEBUG_Q)) \
		$$(which make) -C $${PWD} \
		NODES="$(NODES)" RANKS_PER_NODE="$(RANKS_PER_NODE)" PATTERN="$(PATTERN)" run
	tail -f $(LOGS)
.PHONY: job

jobi:
	qsub -n "$(NODES)" -t "$(MAX_TIME_MIN)" -A "$(ACCOUNT)" -q "$(DEBUG_Q)" \
		--attrs enable_ssh=1 -I
.PHONY: jobi
