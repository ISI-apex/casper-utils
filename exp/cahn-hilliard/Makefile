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

ifneq ($(IN),)
$(DATA_DIR)/ch_%.csv: $(DATA_DIR)/prun_%.rankfile | $(DATA_DIR)/
	mkdir -p "$@.mpl"
	set -o pipefail; \
	env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
	  XDG_CACHE_HOME="$@.cache" MPLCONFIGDIR="$@.mpl" \
	$(call prun-cmd,$*,$<,OMP_NUM_THREADS XDG_CACHE_HOME MPLCONFIGDIR) \
	bash $(PWD)/../fch.sh "$(call tgt-extract,mesh,$*)" \
		"$(call tgt-extract,ranks,$*)" \
		"$(call tgt-tasks-per-node,$*)" \
		--elapsed-out "$@" \
		--solution-out "$(patsubst %.csv,%.pvd,$@)" \
		$(if $(call tgt-extract,steps,$*,1),\
			--steps "$(call tgt-extract,steps,$*)") \
		$(if $(call tgt-tasks,$*),--tasks "$(call tgt-tasks,$*)") \
		$(if $(MEM_PER_NODE),--mem-per-node "$(MEM_PER_NODE)") \
		$(if $(DEDI_NODE_FOR_RANK0),--dedicated-node-for-rank0) \
		$(if $(MONITOR_MEM),--monitor-mem $(MONITOR_MEM)) \
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
	echo $^ | xargs -n 1 sed -n '2p' | sort -n >> $@

$(DATA_DIR)/ch_agg_%.pdf \
$(DATA_DIR)/ch_agg_%.svg: $(DATA_DIR)/ch_agg_%.csv
	$(if $(IN),,$(EPREFIX)/ptools/pstart) python ../plot.py $< $@
