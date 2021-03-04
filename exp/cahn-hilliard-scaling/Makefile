DAT=dat

all: $(DAT)/ch-dsl.pdf $(DAT)/ch-mesh-dist.pdf $(DAT)/ch-mem.pdf

$(DAT)/ch_agg_part-theta.csv $(DAT)/ch_agg_part-summit.csv:
	echo "ERROR: input datasets not found: $^" 1>&2
	echo "  Generate and then manually copy the datasets "
	echo "  from respective exp/cahn-hilliard/*/ dirs" 1>&2
	exit 1

$(DAT)/ch-all.csv: $(DAT)/ch_agg_part-theta.csv $(DAT)/ch_agg_part-summit.csv
	python join.py $^ $@

$(DAT)/ch-subset.csv: $(DAT)/ch-all.csv subset.py
	python subset.py $< $@

$(DAT)/ch-dsl.pdf: $(DAT)/ch-subset.csv plot-dsl.py
	python plot-dsl.py $< $@
$(DAT)/ch-mesh-dist.pdf: $(DAT)/ch-subset.csv plot-mesh-dist.py
	python plot-mesh-dist.py $< $@
$(DAT)/ch-mem.pdf: $(DAT)/ch-subset.csv plot-mem.py
	python plot-mem.py $< $@

# Preserve intermediate artifacts
.SECONDARY:
