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
