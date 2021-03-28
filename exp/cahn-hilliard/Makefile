ifeq ($(filter %.pdf %.svg,$(MAKECMDGOALS)),)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
else
EPREFIX_REQUIRED=
endif

# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

# Prevent worker nodes from quering compiler version (in Firedrake)
FD_CC=gcc
FD_CXX=g++
FD_CCVER=$(shell $(FD_CC) -dumpversion | cut -d. -f-2)
FD_BENCH_DIR=../../apps/firedrake-bench

ifneq ($(IN),)
$(DATA_DIR)/ch_%.csv: $(DATA_DIR)/prun_%.rankfile | $(DATA_DIR)/
	mkdir -p "$(patsubst %.csv,%.mpl,%@)" \
		"$(patsubst %.csv,%.sol,$@)"
	set -o pipefail; \
	OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
	XDG_CACHE_HOME="$(patsubst %.csv,%.cache,$@)" \
	MPLCONFIGDIR="$(patsubst %.csv,%.mpl,$@)" \
	CC="$(FD_CC)" CXX="$(FD_CXX)" CCVER="$(FD_CCVER)" \
	$(call prun-cmd,$*,$<,\
		OMP_NUM_THREADS XDG_CACHE_HOME MPLCONFIGDIR CC CXX CCVER) \
	python "$(FD_BENCH_DIR)/cahn_hilliard/firedrake_cahn_hilliard_bare.py" \
		"$(call tgt-extract,mesh,$*)" \
		"$(call tgt-extract,ranks,$*)" \
		"$(call tgt-tasks-per-node,$*)" \
		--elapsed-out "$@" \
		--solution-out \
		  "$(patsubst %.csv,%.sol,$@)/$(patsubst %.csv,%.pvd,$@)" \
		--obj-dir "$(patsubst %.csv,%.obj,$@)" \
		$(call tgt-arg,$*,steps) \
		$(call tgt-arg,$*,dt) \
		$(call opt-arg,tasks,$(call tgt-tasks,$*)) \
		$(call opt-arg,mem-per-node,$(MEM_PER_NODE)) \
		$(call opt-arg,dedicated-node-for-rank0,$(DEDI_NODE_FOR_RANK0)) \
		$(call opt-arg,monitor-mem,$(MONITOR_MEM)) \
	2>&1 | tee "$@.log"
endif # IN=

define append-dir
$(patsubst %,$(DATA_DIR)/%,$(1))
endef

# 'all' is for the list of desired artifacts in DATS var
# 'part' is for whatever '*.csv' files are in the directory
$(DATA_DIR)/ch_agg_all.csv: $(call append-dir,$(DATS))
$(DATA_DIR)/ch_agg_part.csv: $(wildcard $(DATA_DIR)/ch_mesh-*.csv)
$(DATA_DIR)/ch_agg_%.csv:
	sed -n '1p' $< > $@
	echo $^ | xargs -n 1 sed -n '2,$$p' | sort -n >> $@

$(DATA_DIR)/ch_agg_%.pdf \
$(DATA_DIR)/ch_agg_%.svg: $(DATA_DIR)/ch_agg_%.csv
	$(if $(IN),,$(EPREFIX)/ptools/pstart) python ../plot.py $< $@
