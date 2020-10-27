ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif

ifeq ($(shell which bc),)
$(error The bc calculator app not found in PATH)
endif

BENCH_DIR=../../apps/firedrake-bench
PTOOLS=$(EPREFIX)/ptools

CLUSTER?=discovery
ARCH?=any
NOLOCAL?=
MONITOR?=0
DATA_DIR?=dat

# This is only used for interactive job
NODES?=2

MPIRUN_ARGS_INTERNAL:=

ifeq ($(CLUSTER),discovery:debug)
# only one job allowed in the debug queue.
.NOTPARALLEL:
# note: debug queue limited to 24 CPUs total per job, so to allow
# running with 2 nodes, divide by 2. See note about this param below.
TASKS_PER_NODE?=12
MAX_TIME_MIN?=30
else
# unlimited parallelism is important, since each recipe blocks on SLURM
# NOTE: requires make >=4.3, for other have to specify -j on cmdline
MAKEFLAGS := -j
# note: this is a tricky param, it's for slurm job allocation, it
# is not clear whether '--map-by core' takes it into account to
# determine how many cores does each node have, but the setting
# of this variable should match what map-by uses (assuming map-by
# defaults to number of physical cores per node, we set the var
# to the min number of cores per node across all nodes that the job
# may run on.
# The value of this variable is ignored by *-ppr-N-* targets, which
# set the param to N. For other targets, this value is passed only
# to SLURM for job allocation, it's not passed to mpirun.
TASKS_PER_NODE?=16
MAX_TIME_MIN?=180
endif

DATS_CORE?=\
	times_mesh-512_ranks-16_mapby-core.csv \
	times_mesh-512_ranks-32_mapby-core.csv \
	times_mesh-512_ranks-64_mapby-core.csv \
	times_mesh-1024_ranks-16_mapby-core.csv \
	times_mesh-1024_ranks-32_mapby-core.csv \
	times_mesh-1024_ranks-64_mapby-core.csv \
	times_mesh-1024_ranks-128_mapby-core.csv \
	times_mesh-2048_ranks-64_mapby-core.csv \
	times_mesh-2048_ranks-128_mapby-core.csv \
	times_mesh-2048_ranks-192_mapby-core.csv \
	times_mesh-2048_ranks-256_mapby-core.csv \
	times_mesh-3072_ranks-64_mapby-core.csv \
	times_mesh-3072_ranks-128_mapby-core.csv \
	times_mesh-3072_ranks-192_mapby-core.csv \
	times_mesh-3072_ranks-256_mapby-core.csv \
	times_mesh-4096_ranks-192_mapby-core.csv \
	times_mesh-4096_ranks-256_mapby-core.csv \
	times_mesh-4096_ranks-320_mapby-core.csv \
	times_mesh-4096_ranks-384_mapby-core.csv \
	times_mesh-6144_ranks-256_mapby-core.csv \
	times_mesh-6144_ranks-384_mapby-core.csv \
	times_mesh-6144_ranks-512_mapby-core.csv \

DATS_PPR?=\
	times_mesh-1024_ranks-32_mapby-ppr-2-node.csv \
	times_mesh-1024_ranks-32_mapby-ppr-4-node.csv \
	times_mesh-1024_ranks-32_mapby-ppr-8-node.csv \
	times_mesh-1024_ranks-32_mapby-ppr-16-node.csv \
	times_mesh-1024_ranks-32_mapby-ppr-32-node.csv \

define append-dir
$(patsubst %,$(DATA_DIR)/%,$(1))
endef

all: $(DATA_DIR)/times_mapby-core.csv $(DATA_DIR)/times_mapby-ppr.csv
.PHONY: all

core: $(call append-dir,$(DATS_CORE))
ppr: $(call append-dir,$(DATS_PPR))
.PHONY: core ppr

# A shortcut target for a smoketest for convenience
TEST_DIR=dat-test
TEST_ARGS=CLUSTER=discovery:debug MONITOR=1 DATA_DIR=$(TEST_DIR)
TEST_TGT=$(TEST_DIR)/times_mesh-32_ranks-12_mapby-core.csv
test:
	rm -r $(TEST_DIR)
	$(MAKE) $(TEST_ARGS) $(TEST_TGT)
.PHONY: test

$(DATA_DIR)/:
	mkdir -p $@

# This is optional info... could just rely on default that's max
$(DATA_DIR)/times_mesh-512_%.csv: MAX_TIME_MIN=20
$(DATA_DIR)/times_mesh-1024_%.csv: MAX_TIME_MIN=30
$(DATA_DIR)/times_mesh-2048_%.csv: MAX_TIME_MIN=60
$(DATA_DIR)/times_mesh-3072_%.csv: MAX_TIME_MIN=90
$(DATA_DIR)/times_mesh-4096_%.csv: MAX_TIME_MIN=120
$(DATA_DIR)/times_mesh-6144_%.csv: MAX_TIME_MIN=180

# tgt-extract(key, target_name) -> value
define tgt-extract
$(strip $(subst $(1)-,,$(filter $(1)-%,$(subst _, ,$(subst ., ,$(2))))))
endef

# tgt-tasks-per-node(target_name)
# Extracts N from ppr-N within the target name
# NOTE: won't work for ppr-N-core
define tgt-tasks-per-node
$(strip $(if $(findstring mapby-ppr-,$(1)),\
	$(word 2,$(subst -, ,$(call tgt-extract,mapby,$(1)))),\
	$(TASKS_PER_NODE)))
endef

define gen-map-by
$(strip $(subst -,:,$(1))$(if $(NOLOCAL),:NOLOCAL))
endef

# tgt-map-by(target_name) -> value of --map-by arg for mpirun
define tgt-map-by
$(strip $(call gen-map-by,$(call tgt-extract,mapby,$(1))))
endef

# tgt-nodes(target_name) -> node count (from: ranks/tasks_per_node)
define tgt-nodes
$(strip $(shell echo \
	$(call tgt-extract,ranks,$(1)) / $(call tgt-tasks-per-node,$(1))\
	| bc))
endef

ifeq ($(IN),1)
$(DATA_DIR)/times_%.csv: | $(DATA_DIR)/
	mpirun $(MPIRUN_ARGS_INTERNAL) $(MPIRUN_ARGS) \
		-n "$(call tgt-extract,ranks,$@)" \
		--map-by "$(call tgt-map-by,$@)" \
		python $(BENCH_DIR)/cahn_hilliard/firedrake_cahn_hilliard_bare.py \
			"$(call tgt-extract,mesh,$@)" --elapsed-out "$@"
else
$(DATA_DIR)/times_%.csv: | $(DATA_DIR)/
	MONITOR=$(MONITOR) \
	$(PTOOLS)/psbatch "$(CLUSTER)" "$(ARCH)" all \
		"$(call tgt-nodes,$*)" \
		"$(call tgt-tasks-per-node,$*)" \
		"00:$(MAX_TIME_MIN):00" \
		$$(which make) -C $${PWD} IN=1 EPREFIX=$(EPREFIX) \
		MPIRUN_ARGS="'$(MPIRUN_ARGS)'" VERBOSE="$(VERBOSE)" \
		DATA_DIR="$(DATA_DIR)" \
		$@

job: | $(DATA_DIR)/
	$(PTOOLS)/psalloc "$(CLUSTER)" "$(ARCH)" all \
		"$(NODES)" "$(TASKS_PER_NODE)" "00:$(MAX_TIME_MIN):00" $*
.PHONY: job
endif

$(DATA_DIR)/times_mapby-core.csv: $(call append-dir,$(DATS_CORE))
	sed -n '1p' $(DATA_DIR)/$(firstword $(DATS_CORE)) > $@
	echo $(patsubst %,$(DATA_DIR)/%,$(DATS_CORE)) | \
		xargs -n 1 sed -n '2p' >> $@

# TODO: aggregation target for PPR (not as easy since ppr value
# is only in filename, not inside the CSV file)
$(DATA_DIR)/times_mapby-ppr.csv: $(call append-dir,$(DATS_PPR))
	echo "NOT IMPLEMENTED: $@"