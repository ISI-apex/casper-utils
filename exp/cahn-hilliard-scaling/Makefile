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
	python subset.py -o $@ --rank 0 --mesh 4096,8192 $<

$(DAT)/ch-dsl.pdf: $(DAT)/ch-subset.csv plot-dsl.py
	python plot-dsl.py $< $@
$(DAT)/ch-mesh-dist-8192.pdf: $(DAT)/ch-subset.csv plot-mesh-dist.py
	python plot-mesh-dist.py \
		--mesh 8192 --theta-tpn 24 --summit-tpn 40,42 $< $@
$(DAT)/ch-mesh-dist-4096.pdf: $(DAT)/ch-subset.csv plot-mesh-dist.py
	python plot-mesh-dist.py \
		--mesh 4096 --theta-tpn 48 --summit-tpn 41 $< $@
$(DAT)/ch-mem.pdf: $(DAT)/ch-subset.csv plot-mem.py
	python plot-mem.py $< $@

$(DAT)/ch-4k-steps-25.pdf: $(DAT)/fd-26-prod-5-ch_agg_part.csv plot-basic.py
	python plot-basic.py --mesh 4096 --tpn 42 --timesteps 25 $< $@
$(DAT)/ch-4k-steps-50.pdf: $(DAT)/fd-26-prod-5-ch_agg_part.csv plot-basic.py
	python plot-basic.py --mesh 4096 --tpn 42 --timesteps 50 $< $@
$(DAT)/ch-8k-steps-25.pdf: $(DAT)/fd-26-prod-5-ch_agg_part.csv plot-basic.py
	python plot-basic.py --mesh 8192 --tpn 42 --timesteps 25 $< $@

# Preserve intermediate artifacts
.SECONDARY:
