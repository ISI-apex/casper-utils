define append-dir
$(patsubst %,$(DATA_DIR)/%,$(1))
endef


$(DATA_DIR)/times_mapby-core_all.csv: $(call append-dir,$(DATS_CORE))
$(DATA_DIR)/times_mapby-core_part.csv: $(wildcard $(DATA_DIR)/times_*-core.csv)
#$(DATA_DIR)/times_mapby-core_%.csv:
#	sed -n '1p' $< > $@
#	echo $^ | xargs -n 1 sed -n '2p' | sort -n >> $@

# TODO: aggregation target for PPR (not as easy since ppr value
# is only in filename, not inside the CSV file)
$(DATA_DIR)/times_mapby-ppr-node_all.csv: $(call append-dir,$(DATS_PPR))
$(DATA_DIR)/times_mapby-ppr-node_part.csv: $(wildcard $(DATA_DIR)/times_*-ppr-*-node.csv)
$(DATA_DIR)/times_mapby-%.csv:
	sed -n '1p' $< > $@
	echo $^ | xargs -n 1 sed -n '2p' | sort -n >> $@

$(DATA_DIR)/times_mapby-core_%.pdf \
$(DATA_DIR)/times_mapby-core_%.svg: $(DATA_DIR)/times_mapby-core_%.csv
	$(if $(IN),,$(EPREFIX)/ptools/pstart) python ../plot.py $< $@
