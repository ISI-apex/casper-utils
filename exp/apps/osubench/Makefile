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
	cd $(DIR) && env CC=$(CC) CXX=$(CXX) ./configure --prefix=$(abspath $(PREFIX)) \
		$(CROSS_COMPILE_ARGS) --disable-cuda --disable-openacc

ARTIFACT=mpi/startup/osu_hello
build: $(ARTIFACT) 
$(ARTIFACT): $(DIR)/config.status
	$(MAKE) -C $(DIR)

install: $(INSTALL_PATH)/$(ARTIFACT)
$(INSTALL_PATH)/$(ARTIFACT): $(DIR)/$(ARTIFACT)
	$(MAKE) -C $(DIR) install
